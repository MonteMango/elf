# Performance Audit — Dungeon Battle (simulator, before #1)

Created by Vitalii Lytvynov, 2026-04-27.

## Capture details

| Field | Value |
|---|---|
| Tool | `/usr/bin/sample` (raw output: [`sample.txt`](sample.txt)) |
| Sampling rate | 1 ms |
| Duration | 60 s |
| Process | `elf` (PID 66598), bundle `de.michael-mueller-verlag.mmtravel-app` |
| Device | iPhone 17 Simulator, iOS 26.4 (UDID `6719BD5D-A97E-4492-84FC-1BA0829CD983`) |
| Host | macOS 26.4.1 (25E253), Xcode 26 |
| Build | Debug (`elf.debug.dylib` symbols present) |
| Scenario | Cold launch → tap **Continue** → tap **Dungeon** → 4 rounds of **AUTO + FIGHT** |
| Driver | RocketSim CLI (4-round AUTO+FIGHT loop) |

### Why `sample` instead of `xctrace`

Recorded with `/usr/bin/sample` because `xctrace` is broken for iOS Simulator targets on this Xcode 26 + iOS 26 + macOS 25.4 combination:

- `xctrace --launch <app>` bypasses SceneDelegate and the app sits on the launch screen forever.
- `xctrace --attach <pid>` attaches but never records samples and never honours `--time-limit` or SIGINT (known issue, see Apple Forums threads 741912, 685222, 652221, 705565).
- `xctrace --all-processes` against a simulator UDID hangs identically.
- `SwiftUI` and `Animation Hitches` instruments are explicitly **unsupported on Simulator** by Apple — no workaround.

`sample` is a stock macOS tool that works reliably against any process on the host (a simulator app is just a regular macOS process). It produces a `sample` aggregated call tree, equivalent in shape to Time Profiler's call tree, just without view-body counts or animation-hitch markers.

## Headline numbers

| Metric | Value |
|---|---|
| Main-thread samples total | 49 541 |
| Main-thread idle (`mach_msg2_trap`) | 48 916 (98.7%) |
| **Main-thread active CPU** | ~625 samples ≈ **~1.0% CPU over 60 s** |
| Physical footprint (peak) | 60.9 MB |
| `inProcessAnimationManager` thread idle (`semaphore_wait`) | 42 238 / 42 749 (98.8%) |
| `SwiftUI.AsyncRenderer` thread idle | 1 821 / 1 841 (98.9%) |

**Bottom line:** the app is not CPU-bound on simulator. Findings below are about **code quality and future-proofing** (real device CPU is ~3-5× weaker), not urgent live bottlenecks.

## Findings

### 1. ⚠️ Synchronous combat work on the main actor

**File:** `Packages/elf_Kit/Sources/UILayer/BattleFight/BattleFightViewModel.swift:206`
**Sample evidence:** 28 samples through `closure #1 in closure #9 in closure #1 in BattleFightScreen.body.getter` → `BattleFightViewModel.executeFightRound()`; 20 directly inside `combatRoundExecutor.executeRound(...)` at line 206.

```swift
let result = combatRoundExecutor.executeRound(
    playerSnapshot: left,
    botSnapshot: right,
    playerAttackPoints: leftAttack,
    playerDefensePoints: leftDefense,
    botAttackPoints: rightAttack,
    botDefensePoints: rightDefense
)
```

The fight round runs synchronously inside a `Task { @MainActor in await viewModel.executeFightRound() }` (BattleFightScreen.swift:204). For each pair × 5 pairs the executor crunches damage rolls on the main actor. Tolerable at 5v5 on simulator; on iPhone SE 3 / iPhone 12 mini, or scaled to 10v10, this becomes visible.

**Recommendation:** wrap the per-pair loop body in `Task.detached`, or move `combatRoundExecutor` to a dedicated actor with a background executor. The view model awaits the aggregated result. Estimated effort: ~30 min.

### 2. ⚠️ DI lookup overhead in hot paths

**Files:**
- `Packages/elf_Kit/Sources/.../DebugBattleLogger+Dependency.swift:12`
- `Packages/elf_Kit/Sources/.../DuelPairingService+Dependency.swift:12`

**Sample evidence:** 60 samples in `Dependency.wrappedValue.getter` chain, 58 in `CachedValues.value<A>(for:context:fileID:filePath:function:line:column:)` via `withIssueContext`. Hits land predominantly inside `generateNewRoundPairings()` and `executeFightRound()`.

`swift-dependencies` resolves every `@Dependency` access through a cache lookup that captures source location via `withIssueContext`. Fine for cold paths, expensive when called repeatedly per round.

**Recommendation:** in `BattleFightViewModel.init`, snapshot dependencies once into private stored `let`s:

```swift
private let logger: DebugBattleLogger
private let pairing: DuelPairingService

init() {
    @Dependency(\.debugBattleLogger) var debugLogger
    @Dependency(\.duelPairingService) var pairing
    self.logger = debugLogger
    self.pairing = pairing
}
```

Then use `self.logger` instead of `@Dependency(\.debugBattleLogger) var ...`. Effort: ~15 min.

### 3. ✅ Persistence threading is correct (negative finding worth recording)

**File:** `Packages/elf_Kit/Sources/.../FileGameSaveStorage.swift:21` (`public actor`)
**Sample evidence:** 26 samples in `FileGameSaveStorage.load(slotId:)` were on `Thread_7139346 / DispatchQueue_18: com.apple.root.user-initiated-qos.cooperative` — **not** on the main thread. The earlier suspicion of synchronous file I/O during the Continue tap was wrong.

Architecture works as intended: `actor` runs methods on the cooperative concurrency pool; `await` from `MainMenuViewModel.loadGame()` correctly hops off main. **No change needed.**

### 4. ⚠️ `Self._printChanges()` left in `MainMenuScreen.body`

**File:** `Packages/elf_iOS/Sources/Screens/MainMenuScreen/MainMenuScreen.swift:23`

```swift
var body: some View {
    #if DEBUG
    let _ = Self._printChanges()
    #endif
    ...
}
```

Gated by `#if DEBUG` so it doesn't ship, but every body re-evaluation prints to console. On simulator irrelevant; on real device the I/O on the main thread is non-zero, and the print itself can affect what you measure. The presence of this line also indicates that body-invalidation debugging happened here historically — worth a passing audit of why.

**Recommendation:** remove it, or replace with a `os_signpost` event so the data is structured and can be filtered via `log stream`. Effort: ~5 min.

### 5. ℹ️ Accessibility label hygiene (not a perf finding, surfaced during capture)

**Source:** RocketSim accessibility tree, observed during the scenario.
**Sample evidence:** elements such as `Image|6023cc65-b183-4d41-8742-f1ecb0172942|76|159` and `Image|fa0b6893-6896-4689-a299-b8d271c76b68|76|231` — image asset UUIDs leak into the accessibility label.

Not performance, but degrades VoiceOver UX. Decorative images need `.accessibilityHidden(true)`; meaningful ones need an explicit `.accessibilityLabel("Asuna Yuuki")`. Affects components that render character/avatar images by asset id.

## Negative findings (things that look fine)

| What I checked | Result |
|---|---|
| Image decoding on main thread | Not present. SwiftUI uses `com.apple.SwiftUI.prepare-image` queue (3-8 samples total). |
| `BattleFightScreen.body` invalidation storm | ~30 samples for body.getter over 60 s — normal. |
| `ForEach` identity churn / `_VariadicView_Children.makeContent` | Not in hot path. |
| Main-thread hangs | `inProcessAnimationManager` 99% in `semaphore_wait`, no stuck callbacks. |
| Persistence I/O on main thread | Correctly off-main (Finding #3). |

## Hot stack reference (top elf-code chains)

These are condensed from `sample.txt`. Numbers are sample counts (≈ ms of CPU time).

```
28  BattleFightScreen.body → closure #9 → BattleFightViewModel.executeFightRound()
    └── 20  combatRoundExecutor.executeRound(...)        BattleFightViewModel.swift:206
    └──  5  same call site                               BattleFightViewModel.swift:206
    └──  3  later in executeFightRound                   BattleFightViewModel.swift:235

10  closure #2 in BattleFightScreen.body → BattleFightViewModel.loadInitialData()
    └──  8  generateNewRoundPairings()                   BattleFightViewModel.swift:395
        └──  7  DependencyValues.debugBattleLogger.getter   DebugBattleLogger+Dependency.swift:12
        └──  2  DependencyValues.duelPairingService.getter  DuelPairingService+Dependency.swift:12

 6  closure #7 in BattleFightScreen.body → BattleFightViewModel.autoFillPoints()
    └──  3  playerAttackPoints.setter (Observation withMutation)

28  closure #1 in MainMenuScreen.body → MainMenuViewModel.loadGame()  MainMenuViewModel.swift:57
    (off-main work — see Finding #3)
```

## Limitations of this capture

- **Sampling, not signposts.** No exact body-call counts, no view-update durations, no animation-hitch markers. To get those, you need the `SwiftUI` Instrument on a **physical device** — Apple does not support that template on Simulator.
- **Simulator is not the real device.** Numbers in Findings 1, 2, 4 may be 3–5× higher on iPhone SE 3 / iPhone 12 mini. Do `before/after` comparisons on real hardware before quoting any percentages.
- **CPU only.** No GPU time, no render-server cost, no memory-allocation breakdown.
- **One run.** Sample size of one is not statistical evidence; for tighter numbers, average 3+ runs.

## Suggested next steps

1. Apply Findings #1, #2, #4 (~50 min total).
2. Re-record with the same scenario as `traces/dungeon.simulator.after.1/sample.txt` and diff the top stacks.
3. For real perf numbers (FPS, hitches): connect a physical iPhone over USB and run `xctrace record --template "Time Profiler"` and `--template "SwiftUI"` against it — those instruments work on devices.

## Files in this directory

- [`sample.txt`](sample.txt) — raw `sample(1)` output, ~6 MB, full call graph and binary image map.
- [`audit.md`](audit.md) — this report.

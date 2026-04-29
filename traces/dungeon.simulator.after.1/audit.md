# Performance Audit — Dungeon Battle (simulator, after #1)

Created by Vitalii Lytvynov, 2026-04-29.

Follow-up to [`traces/dungeon.simulator.before.1/audit.md`](../dungeon.simulator.before.1/audit.md). Re-runs the same scenario after applying the fixes for Findings #1 (combat off main actor via `withTaskGroup`) and #2 (snapshot all `@Dependency` resolutions at init).

## Capture details

| Field | Value |
|---|---|
| Tool | `/usr/bin/sample` (raw output: [`sample.txt`](sample.txt)) |
| Sampling rate | 1 ms |
| Duration | 60 s |
| Process | `elf` (PID 116), bundle `de.michael-mueller-verlag.mmtravel-app` |
| Device | iPhone 17 Simulator, iOS 26.4 (UDID `6719BD5D-A97E-4492-84FC-1BA0829CD983`) |
| Host | macOS 26.4.1 (25E253), Xcode 26 |
| Build | Debug (`elf.debug.dylib` symbols present) |
| Scenario | Cold launch → tap **Continue** → tap **Dungeon** → 4 rounds of **AUTO + FIGHT** |
| Driver | RocketSim CLI (4-round AUTO+FIGHT loop) |

Same toolchain and method as the before run — `/usr/bin/sample` instead of `xctrace` (still broken on Xcode 26 simulator, see before-audit). Coordinate-mapping note: this iPhone 17 simulator runs landscape-left (not landscape-right as documented in `.claude/docs/rocketsim-usage.md`); the empirical formula was `px = ly, py = lx` for in-app taps.

## Headline numbers — before / after

| Metric | Before | After | Δ |
|---|---:|---:|---:|
| Main-thread samples total | 49 541 | 50 471 | +930 (longer record) |
| Main-thread idle (`mach_msg2_trap`) | 48 916 (98.7 %) | **50 233 (99.5 %)** | **+0.8 pp** |
| **Main-thread active CPU samples** | **~625 (≈ 1.0 %)** | **~238 (≈ 0.47 %)** | **−62 %** |
| `executeRound` samples on main | 28 | **0** | **−100 %** |
| `executeRound` samples on cooperative pool | 0 | 3 (3 worker threads) | new |
| `generateNewRoundPairings` samples (any thread) | 8 | **0** | **−100 %** |
| `Dependency.wrappedValue.getter` samples (swift-dependencies) | 60 | **0** | **−100 %** |
| `CachedValues.value(for:context:fileID:…)` samples | 58 | **0** | **−100 %** |
| `withIssueContext` samples | (folded into above) | **0** | **−100 %** |
| Physical footprint (peak) | 60.9 MB | 55.8 MB | −8 % |

> The single `wrappedValue` line in the after trace is `SwiftUICore.State.wrappedValue.setter` — SwiftUI's `@State` property wrapper, **not** swift-dependencies. Zero swift-dependencies overhead remains.

**Bottom line:** both audited findings are fully eliminated. The main thread holds essentially nothing of elf-code in a 5v5 dungeon scenario; combat now runs on cooperative pool worker threads as designed.

## Verification of fixes

### Finding #1 — `executeRound` moved off the main actor ✅

Before-trace top stack:
```
28  BattleFightScreen.body → closure #9 → BattleFightViewModel.executeFightRound()
    └── 20  combatRoundExecutor.executeRound(...)        BattleFightViewModel.swift:206
```

After-trace, same call chain only appears under cooperative-pool threads:
```
1 Thread_8583818   DispatchQueue_18: com.apple.root.user-initiated-qos.cooperative  (concurrent)
+ 1 completeTaskWithClosure
+   1 partial apply for thunk for @escaping @isolated(any) … () -> (@out A)
+     1 closure #1 in closure #1 in BattleFightViewModel.runRound(useHeroSelection:)   BattleFightViewModel.swift:242
+       1 ElfCombatRoundExecutor.executeRound(…)                                       ElfCombatRoundExecutor.swift:37
+         1 ElfSnapshotCombatCalculator.calculatePointStatus(…)                        ElfSnapshotCombatCalculator.swift:105
+           1 ElfDodgeService.calculateDodge(…)                                        ElfDodgeService.swift:31
```

Three separate cooperative-pool threads (8583818, 8584213, 8584215) each show `executeRound` running concurrently — the `withTaskGroup`-based parallelism is observable. Main is no longer involved in the per-pair calculation.

### Finding #2 — Per-access `@Dependency` overhead eliminated ✅

Before-trace top hot stack:
```
10  closure #2 in BattleFightScreen.body → BattleFightViewModel.loadInitialData()
    └──  8  generateNewRoundPairings()                   BattleFightViewModel.swift:395
        └──  7  DependencyValues.debugBattleLogger.getter   DebugBattleLogger+Dependency.swift:12
        └──  2  DependencyValues.duelPairingService.getter  DuelPairingService+Dependency.swift:12
```

After-trace:
- `Dependency.wrappedValue.getter`, `CachedValues.value`, `withIssueContext` — **zero occurrences across all threads.**
- `generateNewRoundPairings` — **zero samples** (the per-round pairing call still happens once per round, but each access to its captured deps is now a single stored-property load rather than a TaskLocal+context-push, so it falls below sampling resolution).

The snapshot-at-init refactor (`@Dependency(\.foo) var foo; self.foo = foo` once in `init`, then plain `private let` reads) collapses every later access to a machine-instruction load. The library's diagnostic instrumentation no longer fires on the gameplay loop.

## Remaining elf-code on main thread

The 238 main-thread active samples are dominated by:

| Stack | Samples | Notes |
|---|---:|---|
| `BattleFightScreen.body.getter` | ~12 | SwiftUI body re-evaluation across 4 round transitions; expected, healthy. |
| `BattleFightViewModel.autoFillPoints()` → `playerAttackPoints.setter` → `withMutation` | 4 | One AUTO tap per round × 4 rounds = 4 samples. Trivial. |
| `BattleFightViewModel.playerSnapshot.getter` / `leftTeam.getter` | 1–2 | Observation-tracked reads from view body. Expected. |
| Other (UIKit/SwiftUI runtime, `Self._printChanges` if any) | < 220 | Framework overhead, not elf code. |

Nothing in the elf-code top is a hot stack anymore. Per-round main-actor cost is dominated by SwiftUI view-update work, which is what we want.

## Negative findings (things that look fine)

| What I checked | Result |
|---|---|
| Image decoding on main thread | Not present. |
| `BattleFightScreen.body` invalidation storm | ~12 body.getter samples over 60 s — same as before, no regression. |
| Main-thread hangs | `inProcessAnimationManager` 99 %+ in `semaphore_wait`, no stuck callbacks. |
| Persistence I/O on main thread | Off-main (unchanged from before). |
| `Self._printChanges()` in MainMenuScreen | Not in this trace's window (entered Dungeon directly via Continue). |

## Limitations of this capture

Same caveats as the before run:
- **Sampling, not signposts.** No exact body-call counts or animation-hitch markers (Apple's `SwiftUI` instrument is unsupported on Simulator).
- **Simulator is not the real device.** Numbers are consistent in shape but real device CPU is ~3–5× weaker.
- **One run.** Sample size of one is not statistical evidence; for tighter numbers, average 3+ runs.

The before/after improvements claimed here are robust against single-run noise because the deltas are all order-of-magnitude (60 → 0, 58 → 0, 28 → 0), not 5–10 %.

## What changed in code

Both fixes shipped before this trace:

- `perf(battle): run per-pair combat off main actor with structured concurrency` — adds `BattleFightViewModel.runRound(useHeroSelection:)` that snapshots inputs on Main and dispatches each pair's `executeRound` via `withTaskGroup`. `executeWatchUntilEnd` paces rounds with `Task.sleep(.milliseconds(300))`.
- `perf(di): snapshot @Dependency resolutions at init project-wide` — replaces per-access `@Dependency` resolution (Style A property wrapper) and `Dependency(\.)` typed-wrapper (Style B) with snapshot-in-init across 17 ViewModels and 23 services. `testValue` added to keys exercised by snapshot at init time but not exercised by every test (`attributeRandomizer`, `craftService`, `inventoryService`, `gameRepository`).

## Suggested next steps

1. ✅ Findings #1 and #2 closed by this trace. No further action.
2. Future audit ideas (not blocking):
   - Profile a real device (iPhone SE 3 / 12 mini) over USB to validate the same shape on weaker hardware. `xctrace --template "Time Profiler"` works on devices.
   - If pair counts grow past 20 (e.g. 10v10 mass battles), revisit the `withTaskGroup` body for an explicit sliding-window cap (currently bounded only by cooperative-pool size).
3. Audit Finding #4 (`Self._printChanges()` in MainMenuScreen) is independent and was not in this trace's window — fix in a separate pass when convenient.

## Files in this directory

- [`sample.txt`](sample.txt) — raw `sample(1)` output, ~1.1 MB, full call graph and binary image map.
- [`audit.md`](audit.md) — this report.

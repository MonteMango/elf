# Threading Model

Guidelines for thread safety and concurrency in Elfy.

## Core Principles

1. **UI updates only on MainThread** - All `@Observable` state mutations must happen on MainThread
2. **Heavy computations off MainThread** - Battle simulations, calculations should run on background threads
3. **I/O operations use actors** - File operations use `actor` for thread-safe serialization

## When to Use What

### @MainActor

Use `@MainActor` for:
- **ViewModels** - Always. They hold UI state that SwiftUI observes
- **Methods that mutate @Observable state** - GameService state mutations
- **UI callbacks** - Button actions, navigation handlers

```swift
@MainActor
@Observable
public final class BattleViewModel {
    var playerHP: Int  // UI state - needs MainActor

    func onAttackTapped() {  // UI callback
        // ...
    }
}
```

Do NOT use `@MainActor` for:
- Pure calculation functions
- Data transformation
- Repository protocols
- Services that don't hold observable state

### actor

Use `actor` for:
- **I/O operations** - File read/write, database access
- **Shared mutable state** - Counters, caches that need thread-safe access

```swift
public actor FileGameRepository: GameRepository {
    func save(_ game: Game) async throws {
        // File I/O - actor serializes access
    }
}
```

### Sendable

Use `Sendable` for:
- **Immutable types** - Value types with no mutable state
- **Thread-safe services** - Services with only `let` properties

```swift
// Good - all properties are immutable
public final class ElfDamageService: DamageService, Sendable {
    private let distributionStrategy: StrengthDamageDistributionStrategy
    private let itemsRepository: ItemsRepository
}
```

Use `@unchecked Sendable` ONLY when:
- You've verified all properties are effectively immutable
- Add a comment explaining why it's safe

```swift
// MARK: - Sendable Conformance
// Thread-safe: All properties are let and initialized once
extension ElfDamageService: @unchecked Sendable {}
```

### async/await

Use `async` for:
- **Actual asynchronous work** - Network, file I/O, Task.sleep
- **Methods that call other async methods**
- **Parallel computation** - withTaskGroup

Do NOT use `async` for:
- Synchronous calculations (misleading API)
- Methods with no await inside

```swift
// BAD - no actual async work
func calculate() async -> Int {
    return 1 + 1  // This is synchronous!
}

// GOOD - actual async work
func fetchData() async throws -> Data {
    try await URLSession.shared.data(from: url)
}
```

## Debug Assertions

Use `ThreadingUtils.swift` to catch threading issues during development:

```swift
func heavyCalculation() {
    assertNotMainThread("This should run on background")
    // ... expensive work
}

@MainActor
func updateUI() {
    assertMainThread("UI updates must be on main thread")
    // ... UI work
}
```

## Common Patterns

### ViewModel calling service

```swift
@MainActor
public final class GameDayViewModel {
    private let gameService: GameService

    func onNextDay() {
        // Synchronous state mutation - OK on MainActor
        gameService.advanceToNextDay()

        // Async save - runs on background via actor
        Task {
            try await gameService.saveGame()
        }
    }
}
```

### Parallel computation

```swift
func runMultipleBattles(count: Int) async -> [BattleResult] {
    await withTaskGroup(of: BattleResult.self) { group in
        for _ in 0..<count {
            group.addTask {
                // Each battle runs in parallel on background threads
                await self.battleService.runBattle()
            }
        }
        return await group.reduce(into: []) { $0.append($1) }
    }
}
```

## Architecture Layers

| Layer | Threading | Notes |
|-------|-----------|-------|
| View | MainThread | SwiftUI manages this |
| ViewModel | @MainActor | Holds observable state |
| Service (state) | @MainActor | GameService, EquipmentService |
| Service (calc) | None | DamageService, CritService - thread-safe |
| Repository | actor | File I/O isolation |
| Model | Sendable | Value types, immutable |

## Parallel / Background Work Inventory

The **actual** parallel/non-MainActor work in this codebase — not general rules, a concrete
map. Update this section when you add a new `Task.detached`, `actor`, or `withTaskGroup`.

### Summary table

| Where | Mechanism | What runs off main | Why |
|-------|-----------|--------------------|-----|
| Persistence | `actor FileGameSaveStorage` | All save I/O | File I/O must serialize, can't block main |
| Dev: single auto-battle | `Task.detached(priority: .userInitiated)` | Full battle loop + stat aggregation | Dev tool — simulating 1 battle synchronously would freeze UI |
| Dev: multi-battle simulations | `withTaskGroup(of: BattleResult.self)` | N parallel battle simulations per batch | Dev tool — balance analysis runs 100s of sims; needs CPU parallelism |
| App startup | `async`/`await` sequential | JSON data loading (items, recipes, monsters, etc.) | I/O bound; blocks launch until done |

### 1. Persistence — `actor FileGameSaveStorage`

File: `Packages/elf_Kit/Sources/DataLayer/Services/Persistence/Implementation/FileGameSaveStorage.swift`

The only `actor` in the codebase. Serializes all disk I/O for saves (JSON files in
Application Support). `DefaultGameService.saveGame()` builds the snapshot on MainActor,
then `await gameRepository.save(...)` hops into the actor for the write.

**Every caller of `saveGame()`:**
- `ElfApp.swift:65` — `saveActiveGameIfNeeded()` triggered by `scenePhase.background`/`.inactive`
- `GameDayViewModel` — next day, exit game
- `HuntViewModel`, `QuestViewModel`, `QuestListViewModel`, `BattleFightViewModel`
- `FarmActivityViewModel` — 3 save points across the flow

All call with `try? await gameService.saveGame()` — they fire-and-forget.

**Gotcha:** there's a `TODO` in `DefaultGameService.saveGame()` about coalescing rapid
save calls. Today N saves fire N serial writes. If you're touching save paths, read that
TODO first.

### 2. `Task.detached` — `AutoBattleViewModel` (the canonical pattern)

File: `Packages/elf_Kit/Sources/UILayer/Dev/AutoBattle/AutoBattleViewModel.swift:82`

**This is the reference implementation for "go off main, come back with a result".** When
you need a new piece of background compute, copy this shape:

```swift
// 1. Capture Sendable dependencies before crossing the actor boundary
let ai = botAI
let calculator = snapshotCombatCalculator

// 2. Progress-update closure hops back to MainActor for UI writes
let updateProgress: @Sendable (Double) async -> Void = { [weak self] newProgress in
    await MainActor.run {
        self?.progress = newProgress
    }
}

// 3. Detach the work; priority matches user intent
let result = await Task.detached(priority: .userInitiated) {
    // pure compute here — uses only the captured Sendable services
    // calls `await updateProgress(p)` at checkpoints
}.value

// 4. Apply the result on MainActor (implicit here — we're back on @MainActor)
applyResult(result)
```

Rules this pattern enforces (already wired in the example):
- Captured services are `Sendable` — verified by the compiler
- `@Sendable` on the progress closure so child tasks can call it
- `[weak self]` in the closure — `self` is `@MainActor`, avoid retention cycles
- Body of the `Task.detached` closure reads **no** observable state directly — only
  captured values

### 3. `withTaskGroup` — `MultiBattleViewModel`

File: `Packages/elf_Kit/Sources/UILayer/Dev/AutoBattle/MultiBattleViewModel.swift:100`

**The only `withTaskGroup` in the codebase.** Runs N battle simulations in parallel,
batched. Each batch waits for completion, then progresses. Includes a
`BatchPerformanceTimer` for per-batch CPU metrics — useful reference if you add another
throughput-sensitive batch job.

```swift
let batchResults = await withTaskGroup(of: BattleResult.self) { group in
    for _ in 0..<battlesInBatch {
        group.addTask {
            simService.runSingleBattle(currentBattle)
        }
    }
    // reduce to [BattleResult]
}
```

Notes:
- `simService` (`ElfBattleSimulationService`) is `Sendable` — child tasks capture it directly
- Each child task runs synchronously inside the closure (no further `await`)
- `Task.isCancelled` is checked between batches, not within a batch — cancellation
  granularity is per-batch, which is fine for dev work

### 4. App startup — `ElfDataLoader`

File: `Packages/elf_Kit/Sources/DataLayer/Repositories/DataLoader/Implementation/ElfDataLoader.swift`

`DataLoader: Sendable` protocol: `func loadJSON(_:) async throws -> Data`. Called once at
app launch through `await DefaultGameDataRepository()` inside `ElfAppContainer`. Loads
items, recipes, materials, fish, herbs, ores, monsters, quests — each a separate JSON.
Sequential — no parallelism by design (keeps error surface simple; data is small).

### What is *not* parallel (and why that's correct)

Easy to think gameplay should parallelize — it doesn't need to, because:

- **Turn-based RPG.** Player actions are serial by construction. No frame loop, no
  simulation tick rate.
- **State mutations are synchronous on MainActor.** `craftItem`, `equipWeapon`,
  `advanceToNextDay`, all `add*ToInventory` — fast in-memory writes, no benefit from
  offloading.
- **In-game combat (`BattleFightViewModel`) stays on MainActor.** One battle at a time,
  driven by user input. Only the dev auto-battle tool parallelizes.
- **Hunt / Farm / Craft flows** use `try? await Task.sleep(for:)` for feel-good pacing,
  but the actual work stays on MainActor. The sleep is not compute.
- **Calc services (damage, crit, dodge, armor)** are `Sendable` — they *could* run
  anywhere, but callers use them synchronously from MainActor. That's fine. "Sendable"
  means "callable from anywhere", not "runs in background".

### When to add a new parallel path

If a new feature needs background compute, check:

1. **Is it compute-bound and > ~16ms?** If no, keep it on MainActor. A 5ms call off main
   costs more in context-switching than running it inline.
2. **Is every input Sendable?** If no, refactor the input types first. Don't use
   `@unchecked Sendable` without a safety note.
3. **Is the callsite already `async`?** If no, consider whether wrapping the caller in
   `.task { ... }` is appropriate, or whether a dedicated detached Task is justified.
4. **Where does the result go?** If straight into observable state, apply it on
   MainActor atomically — don't touch `@MainActor` state from the background closure.

Then follow the `AutoBattleViewModel` template above.

## Observation Rules (@Observable + SwiftUI)

After the migration from AsyncStream to `@Observable` (commit `78c34c6`), UI reactivity
works via **per-property access tracking**, not subscription streams. A few rules follow
from that and have already bitten real bugs — read these before touching observable state.

### Writing to an `@Observable` property fires observation for that property only

`PlayerStore` (on the `DefaultGameService.player` chain) exposes `equipped`, `inventory`,
`currentExp`, etc. Each is independently tracked. Writing `player.equipped = newValue`
invalidates only views that read `.equipped` — not those reading `.inventory`.

Corollary: **don't wrap writes in closures "for scoping"**. A plain assignment fires the
exact same observation as an `inout` closure, with less ceremony. Prefer:

```swift
// GOOD — direct write, explicit intent
var equipped = gameService.player.equipped
equipped.weapons = .twoHanded(weapon: weapon)
gameService.player.equipped = equipped
```

over the closure-based escape hatches (`modifyEquipment`, `modifyInventory`) that previously
existed on `GameStateService`. Those were removed in the refactor that replaced `modifyInventory`
with explicit `craftItem` and replaced `modifyEquipment` with direct writes — see the ADR for
rationale.

### `@Observable` class property reads register tracking — even in helper methods

A read of an `@Observable` property inside a helper called from a view's `body` registers
that property as a body-tracked dependency. When it later changes (including to `nil`),
`body` re-runs synchronously — and any `nil`-unsafe code path the helper hits will trip.

**Guidance:**
- If a screen's `body` reads optional observable state that can go `nil` during unmount,
  guard the body so the screen tolerates the transient `nil`. The canonical implementation
  of this pattern in this codebase is `SessionRouteView` — it unwraps
  `coordinator.sessionModel: GameSessionModel?` before constructing the session-bound
  screen, so screens themselves never see a nil session.
- `Task.yield()` alone is **not enough** to guarantee the view has unmounted before you
  nil out an observable. The mutation itself re-triggers the observing body synchronously.
- Prefer cleanup ordering where the observable goes nil *after* the view is gone from the
  hierarchy, or where the view tolerates the transient nil state.

### `@ObservationIgnored` for dependencies

Services stored on an `@Observable` class must use `@ObservationIgnored`. This applies to
both raw stored properties and `@Dependency` fields injected via swift-dependencies — see
`dependency-injection.md` for the canonical patterns.

```swift
@MainActor
@Observable
public final class DefaultGameService: GameService {
    public var player: PlayerStore                                      // tracked
    @ObservationIgnored @Dependency(\.gameRepository) private var gameRepository  // not tracked
    @ObservationIgnored @Dependency(\.craftService)   private var craftService    // not tracked
}
```

Without `@ObservationIgnored`, every read of a service property from inside the observable
registers tracking noise — worst case it causes spurious re-evaluations when the service
reference is reassigned (rare, but happens in tests).

### Don't trigger observation changes from inside `body`

`body` is read-only w.r.t. observable state. If you find yourself writing to observable
state in a view body or computed property read by body, you're creating a render loop.
Mutate from event handlers (`.task`, `.onAppear`, button actions), not from body.

## Checklist When Changing Observable State

- [ ] State lives on a `@MainActor @Observable` class (usually on `PlayerStore` or `DefaultGameService`)
- [ ] Dependencies on that class have `@ObservationIgnored`
- [ ] Mutation method is explicit (`craftItem(...)`, `equipWeapon(...)`) — not a closure escape hatch
- [ ] Heavy work (I/O, compute) runs via `Task.detached` or an `actor`, and the result is applied on MainActor atomically
- [ ] If the state is optional and can go nil during view unmount, the reading view guards on nil

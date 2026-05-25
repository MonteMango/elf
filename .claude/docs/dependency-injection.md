# Dependency Injection

The project uses [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) from Point-Free. Each service has a `*+Dependency.swift` file co-located with its protocol that declares the key. Services and ViewModels **snapshot all dependencies once in `init`** into plain `private let` properties (canonical pattern; see below). App-startup roots are registered once via `prepareDependencies` in `DependencyBootstrap`. Session-scoped ViewModels are constructed through factories on `GameSessionModel`.

---

## Declaring a dependency

Each service has a sibling file `{Service}+Dependency.swift` that:
1. Adds an accessor on `DependencyValues`.
2. Declares a private `DependencyKey` enum with `liveValue` (and optionally `testValue` / `previewValue`).

### Minimal example

```swift
import Dependencies

extension DependencyValues {
    public var damageService: any DamageService {
        get { self[DamageServiceKey.self] }
        set { self[DamageServiceKey.self] = newValue }
    }
}

private enum DamageServiceKey: DependencyKey {
    static var liveValue: any DamageService { ElfDamageService() }
}
```

### With `testValue` (NoOp logger)

```swift
private enum DebugBattleLoggerKey: DependencyKey {
    static var liveValue: any DebugBattleLogger {
        ConsoleDebugBattleLogger(categories: [])
    }
    static var testValue: any DebugBattleLogger { NoOpDebugBattleLogger() }
}
```

### Async-loaded root with `fatalError` liveValue + `previewValue`

For repositories sourced from async-loaded data (registered in `DependencyBootstrap`), `liveValue` traps to make missing-bootstrap bugs loud:

```swift
private enum ItemsRepositoryKey: DependencyKey {
    static var liveValue: any ItemsRepository {
        fatalError("ItemsRepository must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It is sourced from async-loaded GameDataRepository.")
    }

    #if DEBUG
    static var previewValue: any ItemsRepository {
        ElfItemsRepository(heroItems: .empty)
    }
    #endif
}
```

**Choose values per dependency:**
| Slot | When to provide |
|------|-----------------|
| `liveValue` | Always. Real implementation, or `fatalError` for async-loaded roots. |
| `testValue` | **Provide whenever the dep can land on a snapshot-in-init code path that tests don't override.** Required for cold-path deps that are resolved at construction but not exercised by every test. Default to `liveValue` if the live impl is pure; otherwise a NoOp (e.g., file/network stubs). |
| `previewValue` | Wrap in `#if DEBUG`. Used by SwiftUI previews. Provide for any dep whose `liveValue` is expensive, async, or `fatalError`. |

---

## Canonical pattern: snapshot at init

Resolve every `@Dependency` **once** inside `init` and store it as a plain `private let`. This is the only pattern in the codebase. It works uniformly for `@MainActor @Observable` ViewModels, plain `Sendable final class` services, and `actor`s — there is no isolation-specific variant.

```swift
@MainActor
@Observable
public final class HuntViewModel {

    private let gameService: any GameService
    private let monsterRepository: any MonsterRepository
    private let snapshotBuilder: any CombatantSnapshotBuilder
    private let progressionService: any ProgressionService

    public init(gameService: any GameService) {
        @Dependency(\.monsterRepository) var monsterRepository
        @Dependency(\.snapshotBuilder) var snapshotBuilder
        @Dependency(\.progressionService) var progressionService
        self.monsterRepository = monsterRepository
        self.snapshotBuilder = snapshotBuilder
        self.progressionService = progressionService

        self.gameService = gameService
    }
}
```

For services:

```swift
public final class DefaultBattleResultCalculator: BattleResultCalculator {

    private let huntService: any HuntService
    private let dropService: any DropService
    private let progressionService: any ProgressionService

    public init() {
        @Dependency(\.huntService) var huntService
        @Dependency(\.dropService) var dropService
        @Dependency(\.progressionService) var progressionService
        self.huntService = huntService
        self.dropService = dropService
        self.progressionService = progressionService
    }
}
```

**Why this and not the property wrapper.** Each access to `@Dependency(\.foo) var foo` resolves through a TaskLocal lookup plus a `withIssueContext` source-location capture. Cheap once, expensive in per-pair / per-frame loops (see `traces/dungeon.simulator.before.1/audit.md`, Finding #2). Snapshotting collapses every later access to a single stored-property load.

**Why no Sendable boilerplate.** A `private let foo: any FooService` where the protocol declares `: Sendable` makes the host class auto-derive `Sendable` (when other stored properties are also Sendable). No `@unchecked`, no typed-wrapper indirection. The previous `private let _foo = Dependency(\.foo); private var foo: any Foo { _foo.wrappedValue }` form existed only to keep `final class` services Sendable while still resolving lazily — that need disappears with snapshotting.

**Why no `@ObservationIgnored`.** The `@Observable` macro tracks `var` properties only; immutable `let` storage is invisible to it. The annotation is unnecessary on snapshotted deps.

**Greedy resolution invariant.** Resolution happens at `init` time, not at first access. Two consequences:
1. **Tests must construct the SUT _inside_ the `withDependencies` override block** (the project already does this everywhere).
2. **Cold-path deps need a `testValue`.** A test that constructs a service and only exercises a subset of its methods will still cause `init` to resolve every declared dep. Any key without `testValue` will trip swift-dependencies' "no test implementation" assertion. Add `static var testValue: any Foo { liveValue }` for pure deps, or a NoOp stub for deps with side-effects (file I/O, network).

### Anti-pattern — don't use the property wrapper as storage

```swift
// ❌ Do NOT do this on long-lived classes (ViewModels, services, sessions).
@ObservationIgnored
@Dependency(\.progressionService) private var progressionService
```

This lazily resolves the dependency on **every** access — a TaskLocal lookup plus a source-location capture per call. On a long-lived `@Observable` ViewModel each computed-property read that touches a dep pays that cost; in hot loops (per-frame or per-row) it adds up. It also masks resolution failures: a missing `testValue` won't trip at `init` time but only on first read, which can hide bugs until the affected code path runs.

Snapshot the value in `init` into a `private let` instead (pattern above). The `@Dependency` property wrapper is fine as a **local `var`** inside `init` to pull the value out — that's exactly how the canonical pattern uses it.

---

## App bootstrap

One-shot, before the root UI is shown. Located at `Packages/elf_iOS/Sources/DependencyInjection/DependencyBootstrap.swift`:

```swift
@MainActor
public enum DependencyBootstrap {
    public static func run() async {
        let gameData = await DefaultGameDataRepository()

        prepareDependencies {
            $0.gameDataRepository = gameData
            $0.itemsRepository = gameData.items
            $0.monsterRepository = gameData.monsters
            $0.fishRepository = gameData.fish
            $0.herbRepository = gameData.herbs
            $0.oreRepository = gameData.ores
            $0.materialRepository = gameData.materials
            $0.recipeRepository = gameData.recipes
            $0.questRepository = gameData.quests
        }
    }
}
```

Called from `ElfApp` inside a splash-`.task` that gates the root UI behind a `ProgressView` until completion. All downstream services compose via their own `liveValue`s — there is no manual wiring.

**Add a new bootstrap root** only when the dependency is async-loaded at startup (e.g., a new repository sourced from `GameDataRepository`). Otherwise, plain `liveValue` is enough.

---

## Session-scoped state — `GameSessionModel`

`Packages/elf_Kit/Sources/UILayer/GameSession/GameSessionModel.swift` owns the active game and exposes factory methods for session-bound ViewModels:

```swift
@MainActor
@Observable
public final class GameSessionModel {
    public let gameService: any GameService
    public let dayState: GameDayStateViewModel

    public init(gameService: any GameService) {
        self.gameService = gameService
        self.dayState = GameDayStateViewModel(gameService: gameService)
    }

    public func makeHuntViewModel() -> HuntViewModel {
        HuntViewModel(gameService: gameService)
    }
    // ... makeFarmViewModel, makeCraftViewModel, makeQuestViewModel, makeGameDayViewModel, ...
}
```

**Why a non-optional `gameService`.** It makes it structurally impossible to construct a session-bound VM without a live session — no runtime `fatalError` guards needed in factories. Optionality lives one level up (`AppCoordinator.sessionModel: GameSessionModel?`) and is unwrapped by `SessionRouteView` before reaching the screen.

**Lifecycle.** `AppCoordinator.startGame(_:playTime:)` creates the model; `endGame()` releases it. ViewModels stay alive as long as the screen retains them.

**Adding a session-bound feature:** add `make{Name}ViewModel()` here, then call it from the screen's `init(session:)`.

---

## Tests

Override dependencies with `withDependencies { ... } operation: { ... }` from `DependenciesTestSupport`. Two common shapes:

### Per-class mock setup via `invokeTest`

For test classes that share a fixed mock set across all tests:

```swift
final class ElfSnapshotCombatCalculatorTests: XCTestCase {

    override func invokeTest() {
        let damage = MockDamageService()
        let dodge = MockDodgeService()
        let crit = MockCritService()
        self.mockDamageService = damage

        withDependencies {
            $0.damageService = damage
            $0.dodgeService = dodge
            $0.critService = crit
        } operation: {
            super.invokeTest()
        }
    }
}
```

### Inline override per test

```swift
let validator = withDependencies {
    $0.itemsRepository = repository
} operation: {
    ElfWeaponValidator()
}
```

### NoOp loggers via `testValue`

`debugBattleLogger` and `debugGameLogger` use `NoOpDebugBattleLogger` / `NoOpDebugGameLogger` as `testValue`. Tests do not need to override them — combat/game tests run silently by default.

---

## Previews

Bootstrap inside the preview body so previews work standalone:

```swift
#if DEBUG
#Preview {
    @Previewable @State var coordinator: AppCoordinator?
    @Previewable @State var router = AppRouter()

    if let coordinator, let session = coordinator.sessionModel {
        NavigationStack(path: $router.navigationPath) {
            HuntScreen(session: session)
                .environment(router)
                .environment(coordinator)
        }
    } else {
        ProgressView()
            .task {
                await DependencyBootstrap.run()
                let c = AppCoordinator()
                c.initializePreviewSession(game: PreviewGame.createMockGame())
                coordinator = c
            }
    }
}
#endif
```

For non-session screens, drop the `sessionModel` check and the `initializePreviewSession` call.

`PreviewGame.createMockGame()` (`Packages/elf_iOS/Sources/Screens/PreviewGame.swift`) provides mock data. Add a `previewValue` to a `+Dependency.swift` file (under `#if DEBUG`) for any dep whose `liveValue` would be expensive, async, or trap.

---

## Common pitfalls

See `common-mistakes.md` for full examples. Highlights:

- Don't pass services through `init` parameters — resolve them via `@Dependency(\.foo) var foo` inside `init` and snapshot to `self.foo`. The only init parameters are session-scoped state (`gameService: any GameService`) or screen-scoped state (`battle: Battle`, `activity: FarmActivity`).
- Don't use `@unchecked Sendable` on a class with `@Dependency` — snapshot to `private let`s instead. The host class auto-derives `Sendable` from its stored Sendable properties.
- Don't bypass `GameSessionModel` for session-bound VMs (`HuntViewModel(gameService: coordinator.sessionModel!.gameService)` ⛔). Always go through `session.makeXxxViewModel()`.
- Don't store `@Dependency(\.foo) var foo` as a class-level property — that's the old per-access pattern, removed in favor of snapshot-at-init.
- In tests, **always construct the SUT inside `withDependencies { ... } operation: { ... }`**. Greedy resolution at `init` means any override applied after construction is ignored. If a key trips "no test implementation", add `testValue` to it (default to `liveValue` for pure deps, NoOp stub for deps with side-effects).

---

## Reference: where things live

| Concern | Path |
|---------|------|
| `+Dependency.swift` files | `Packages/elf_Kit/Sources/DataLayer/.../{Service}/{Service}+Dependency.swift` |
| App bootstrap | `Packages/elf_iOS/Sources/DependencyInjection/DependencyBootstrap.swift` |
| Session model + VM factories | `Packages/elf_Kit/Sources/UILayer/GameSession/GameSessionModel.swift` |
| Session lifecycle | `Packages/elf_iOS/Sources/Coordinator/AppCoordinator.swift` |
| Route → session adapter | `Packages/elf_iOS/Sources/Navigation/SessionRouteView.swift` |
| Preview mock data | `Packages/elf_iOS/Sources/Screens/PreviewGame.swift` |

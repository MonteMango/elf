# Dependency Injection

The project uses [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) from Point-Free. Each service has a `*+Dependency.swift` file co-located with its protocol that declares the key. Services and ViewModels resolve dependencies via `@Dependency` (one of two patterns, see below). App-startup roots are registered once via `prepareDependencies` in `DependencyBootstrap`. Session-scoped ViewModels are constructed through factories on `GameSessionModel`.

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
| `testValue` | When tests should default to a NoOp/stub (e.g., loggers) instead of forcing per-test overrides. |
| `previewValue` | Wrap in `#if DEBUG`. Used by SwiftUI previews. Provide for any dep whose `liveValue` is expensive, async, or `fatalError`. |

---

## Two injection styles

The bare `@Dependency` property wrapper from the library is **not `Sendable`**. The right pattern depends on the host class's isolation.

### Style A — `@Dependency` property wrapper

For `@MainActor` types and actor-isolated types. Inside `@Observable` classes, `@ObservationIgnored` is required so dependency reads don't register as body-tracked properties.

```swift
@MainActor
@Observable
public final class HuntViewModel {

    private let gameService: any GameService

    @ObservationIgnored
    @Dependency(\.monsterRepository) private var monsterRepository

    @ObservationIgnored
    @Dependency(\.snapshotBuilder) private var snapshotBuilder

    @ObservationIgnored
    @Dependency(\.progressionService) private var progressionService

    public init(gameService: any GameService) {
        self.gameService = gameService
    }
}
```

### Style B — typed-wrapper Dependency

For plain `Sendable` `final class` services (most things in `DataLayer/Services/`). Lets the class be `Sendable` without `@unchecked`:

```swift
public final class DefaultBattleResultCalculator: BattleResultCalculator {

    private let _huntService = Dependency(\.huntService)
    private var huntService: any HuntService { _huntService.wrappedValue }

    private let _dropService = Dependency(\.dropService)
    private var dropService: any DropService { _dropService.wrappedValue }

    private let _progressionService = Dependency(\.progressionService)
    private var progressionService: any ProgressionService { _progressionService.wrappedValue }

    public init() {}
}
```

**Why both forms exist.** The `@Dependency` property wrapper (`Style A`) is not `Sendable`, so storing it on a non-actor `final class` would force `@unchecked Sendable`. `Dependency` itself (the value type — `Style B`) **is** `Sendable`, so `let _foo = Dependency(\.foo)` keeps the class `Sendable` cleanly. The computed `var foo: any Foo { _foo.wrappedValue }` resolves lazily through TaskLocal with the same override semantics as the property wrapper.

**Rule of thumb:**
- `@MainActor` / actor host → Style A.
- Plain `final class: Sendable` host → Style B.

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

- Don't pass services through `init` — use `@Dependency`. The only init parameters are session-scoped state (`gameService: any GameService`) or screen-scoped state (`battle: Battle`, `activity: FarmActivity`).
- Don't use `@unchecked Sendable` to silence Swift 6 errors on a class with `@Dependency` — switch to the typed-wrapper pattern.
- Don't bypass `GameSessionModel` for session-bound VMs (`HuntViewModel(gameService: coordinator.sessionModel!.gameService)` ⛔). Always go through `session.makeXxxViewModel()`.
- In `@Observable` classes, every `@Dependency` must be `@ObservationIgnored`, otherwise reads register tracking and cause spurious body re-runs.

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

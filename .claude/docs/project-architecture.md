# Project Architecture - Elfy

## MVVM Architecture

```
View (Screen/ScreenContent)
    ↓ @State var viewModel
ViewModel (@Observable)
    ↓ uses
Services / Repositories / Builders
    ↓ manages
Models (Data)
```

### Principles:
- **View** — clean, no business logic, only depends on ViewModel
- **ViewModel** — clean, no business logic, only uses Services/Repositories/Builders
- **Services** — all business logic

---

## Package Structure

```
/Packages
├── elf_Kit/          # DataLayer - services, models, repositories
├── elf_SwiftUI/      # Shared UI components
└── elf_iOS/          # UILayer - app screens
```

---

## Screen Pattern: *Screen + *ScreenContent

Each screen consists of two files:

### *Screen.swift — DI container
```swift
internal struct BattleFightScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    let battle: Battle

    internal var body: some View {
        BattleFightScreenContent(
            viewModel: container.makeBattleFightViewModel(battle: battle)
        )
    }
}
```

### *ScreenContent.swift — UI implementation
```swift
internal struct BattleFightScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: BattleFightViewModel

    internal init(viewModel: BattleFightViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    internal var body: some View {
        // UI implementation
    }
}
```

### Why two files?
1. **Screen** — only DI injection via `container.make*ViewModel()`
2. **ScreenContent** — full UI implementation with `@State` for ViewModel

---

## Dependency Injection

### ElfAppDependencyContainer

**Path:** `Packages/elf_iOS/Sources/DependencyInjection/ElfAppDependencyContainer.swift`

```swift
@Observable
public final class ElfAppDependencyContainer {

    // Long-lived dependencies (singletons)
    public let itemsRepository: ItemsRepository
    public let attributeService: AttributeService

    // Game session state
    public private(set) var activeGameService: GameService?

    public init() {
        // Initialize dependencies
    }

    // Factory methods for ViewModel
    @MainActor
    public func makeBattleFightViewModel(battle: Battle) -> BattleFightViewModel {
        return BattleFightViewModel(
            battle: battle,
            botAI: self.botAI,
            // ... other dependencies
        )
    }
}
```

### Usage in View
```swift
@Environment(ElfAppDependencyContainer.self) private var container

// Create ViewModel via factory method
let vm = container.makeGameDayViewModel(game: game)
```

---

## ViewModel Structure

**Path:** `Packages/elf_Kit/Sources/UILayer/{Feature}/{Feature}ViewModel.swift`

```swift
@Observable
@MainActor
public final class HuntViewModel {

    // Dependencies (injected via init)
    private let gameService: GameService
    private let monsterRepository: MonsterRepository

    // Computed properties (derived data)
    public var currentActionPoints: Int {
        gameService.game.gameState.currentActionPoints
    }

    public var canHunt: Bool {
        currentActionPoints >= huntCost
    }

    public init(
        gameService: GameService,
        monsterRepository: MonsterRepository
    ) {
        self.gameService = gameService
        self.monsterRepository = monsterRepository
    }

    // Actions (called from View)
    public func startHunt() async -> Battle? {
        guard canHunt else { return nil }
        gameService.spendActionPoints(huntCost)
        // ...
    }
}
```

---

## Navigation

### AppRouter
```swift
@Observable
public final class AppRouter {
    public var navigationPath = NavigationPath()
    public var presentedModal: ModalRoute?

    public func navigate(to route: AppRoute) {
        navigationPath.append(route)
    }

    public func presentModal(_ modal: ModalRoute) {
        presentedModal = modal
    }
}
```

### AppRoute (enum-based routing)
```swift
public enum AppRoute: Hashable {
    case mainMenu
    case gameSession(Game, playTime: TimeInterval)
    case hunt
    case battleFight(Battle)
}
```

### Usage in View
```swift
@Environment(AppRouter.self) private var router

// Navigation
router.navigate(to: .hunt)

// Modal
router.presentModal(.battleResult(result))
```

---

## Adding a New Screen

1. **Create ViewModel** in `elf_Kit/Sources/UILayer/{ScreenName}/`
```swift
@Observable
@MainActor
public final class NewScreenViewModel {
    private let someService: SomeService

    public init(someService: SomeService) {
        self.someService = someService
    }
}
```

2. **Create Screen** in `elf_iOS/Sources/Screens/{ScreenName}/`
```swift
// NewScreen.swift
internal struct NewScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    internal var body: some View {
        NewScreenContent(viewModel: container.makeNewScreenViewModel())
    }
}

// NewScreenContent.swift
internal struct NewScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: NewScreenViewModel

    internal init(viewModel: NewScreenViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    internal var body: some View {
        // UI
    }
}
```

3. **Add factory method** to `ElfAppDependencyContainer`
```swift
@MainActor
public func makeNewScreenViewModel() -> NewScreenViewModel {
    return NewScreenViewModel(someService: self.someService)
}
```

4. **Add Route** to `AppRoute.swift`
```swift
case newScreen
```

---

## File Structure

```
Packages/elf_iOS/Sources/
├── Screens/
│   ├── {ScreenName}/
│   │   ├── {ScreenName}Screen.swift
│   │   ├── {ScreenName}ScreenContent.swift
│   │   └── Components/
├── DependencyInjection/
│   └── ElfAppDependencyContainer.swift
└── Navigation/
    ├── AppRouter.swift
    ├── AppRoute.swift
    └── ModalRoute.swift

Packages/elf_Kit/Sources/UILayer/
└── {Feature}/
    └── {Feature}ViewModel.swift
```

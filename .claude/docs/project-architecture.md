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
- **ViewModel** — orchestration only, no business logic, delegates to Services
- **Model** — pure data containers, no business logic
- **Services/Repositories/Builders/Validators** — all business logic lives here

---

## Business Logic Rules

### What IS business logic:
- Calculations that use game constants (exp formulas, damage formulas)
- Validation rules (name validation, equipment compatibility)
- Factory methods that depend on services
- Data transformation with game rules
- UI formatting (description lines, stat display)

### What is NOT business logic (can stay in Models):
- Simple getters (count, isEmpty)
- Simple math (progress = current / max)
- Identity checks (isAlive = hp > 0)
- Collection accessors (filter by simple condition)

### Where business logic should live:

| Type | Location | Example |
|------|----------|---------|
| Level calculations | `ProgressionService` | `calculateLevel(exp:)` |
| Item creation | `*Factory` | `ElfInfoFactory` |
| Stat calculations | `*Calculator` | `BattleResultCalculator` |
| Validation | `*Validator` | `CharacterNameValidator` |
| Data queries | `*Repository` | `MonsterRepository` |
| UI formatting | `*Formatter` | `ItemDetailsFormatter` |
| Aggregation | `*Aggregator` | `BattleStatisticsAggregator` |

### ❌ Anti-patterns (avoid):

```swift
// BAD: Business logic in Model
struct House {
    var totalLevel: Int {
        members.reduce(0) { $0 + max(1, min(12, $1.exp / 100)) }
    }
}

// BAD: Factory method with service dependency in Model
extension FarmSkillInfo {
    static func make(for activity: FarmActivity,
                     progressionService: ProgressionService) -> FarmSkillInfo
}

// BAD: UI formatting in Model
struct WeaponDetails {
    var descriptionLines: [String] {
        ["Attack: \(attackMin)-\(attackMax)", ...]
    }
}
```

### ✅ Correct patterns:

```swift
// GOOD: Pure data container
struct House {
    let totalLevel: Int  // Computed by HouseService at creation
}

// GOOD: Service handles creation
class DefaultFarmActivityService {
    func getSkillInfo(for activity: FarmActivity, player: ElfInfo) -> FarmSkillInfo
}

// GOOD: Formatter in UILayer
struct ItemDetailsFormatter {
    func descriptionLines(for details: ItemDetails) -> [String]
}
```

---

## Package Structure

```
/Packages
├── elf_Kit/          # DataLayer - services, models, repositories
├── elf_SwiftUI/      # Shared UI components + Design System
└── elf_iOS/          # UILayer - app screens
```

---

## Design System (elf_SwiftUI)

All styles are centralized in `elf_SwiftUI/Sources/DesignSystem/`:

```
DesignSystem/
├── ElfColors.swift       # Colors (Text, Background, Button, Battle, Rarity, etc.)
├── ElfSpacing.swift      # Spacing scale (xxxs→huge) + semantic aliases
├── ElfSizing.swift       # Component sizes (Icon, Button, ProgressBar, Cell)
├── ElfFonts.swift        # Typography (Size scale + Component fonts)
├── ElfCornerRadius.swift # Border radius scale
├── ElfShadows.swift      # Shadow presets + .elfShadow() extension
└── ElfAnimations.swift   # Animation timing constants
```

### Rules:
1. **DO NOT** create `*Constants.swift` files in `elf_iOS` screens
2. **ALWAYS** use tokens from `ElfColors`, `ElfSpacing`, `ElfSizing`, etc.
3. **EXTEND** design system if new values needed (add to elf_SwiftUI, not locally)

### Usage:
```swift
import elf_SwiftUI

// Colors
.foregroundColor(ElfColors.Text.primary)
.background(ElfColors.Background.panel)

// Spacing
.padding(ElfSpacing.section)
VStack(spacing: ElfSpacing.component)

// Sizing
.frame(width: ElfSizing.Button.widthStandard, height: ElfSizing.Button.height)

// Fonts
.font(ElfFonts.Component.heroName)

// Shadows
.elfShadow(ElfShadows.button)
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

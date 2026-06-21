# Project Architecture - Elfy

## MVVM Architecture

```
View (Screen)
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
- **Services/Repositories/Persistence/Builders/Validators** — all business logic lives here

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
| UI formatting | `*Formatter` | `ItemAttributesFormatter` |
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
struct WeaponAttributes {
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
struct ItemAttributesFormatter {
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

## Dependency Injection

The project uses **swift-dependencies** (Point-Free). Each service has a sibling `{Service}+Dependency.swift` file declaring a key on `DependencyValues`. ViewModels and services resolve them via `@Dependency` (or the typed-wrapper variant — see below). App-startup roots are registered once in `DependencyBootstrap.run()`.

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

Two injection styles, picked by host isolation:
- **`@Dependency` property wrapper** for `@MainActor` and actor-isolated classes (in `@Observable` classes mark with `@ObservationIgnored`).
- **Typed-wrapper Dependency** (`let _foo = Dependency(\.foo); var foo: any Foo { _foo.wrappedValue }`) for plain `Sendable` `final class` services — keeps the class `Sendable` without `@unchecked`.

Session-scoped ViewModel factories live on `GameSessionModel` (`Packages/elf_Kit/Sources/UILayer/GameSession/GameSessionModel.swift`), which holds the non-optional `gameService` and exposes `make*ViewModel()` for every session-bound feature. Optionality lives one level up on `AppCoordinator.sessionModel` and is unwrapped by `SessionRouteView` before reaching a screen.

> **Full reference** — declaring deps, `liveValue`/`testValue`/`previewValue` rules, both injection styles, app bootstrap, tests, previews, and pitfalls — see `dependency-injection.md`.

---

## Screen Pattern: Single-file Screen

Each screen is one file at `Packages/elf_iOS/Sources/Screens/{Name}Screen/{Name}Screen.swift`. The ViewModel is created in `init` and stored as `@State`. Three init shapes exist:

### Session-bound (most game screens)

```swift
struct HuntScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: HuntViewModel
    private let dayStateViewModel: GameDayStateViewModel

    init(session: GameSessionModel) {
        self._viewModel = State(initialValue: session.makeHuntViewModel())
        self.dayStateViewModel = session.dayState
    }

    var body: some View { /* UI */ }
}
```

Routes wire these via `SessionRouteView` (see Navigation section).

### App-scoped (pre-session — main menu, character creation)

```swift
struct MainMenuScreen: View {
    @State private var viewModel: MainMenuViewModel

    init() {
        self._viewModel = State(initialValue: MainMenuViewModel())
    }
}
```

The VM resolves all its deps via `@Dependency`. No `GameSessionModel`, no `SessionRouteView`.

### Optional session (battle screens reachable from a dev path)

```swift
internal struct BattleFightScreen: View {
    @State private var viewModel: BattleFightViewModel

    internal init(battle: Battle, session: GameSessionModel?) {
        self._viewModel = State(initialValue: BattleFightViewModel(
            battle: battle,
            gameService: session?.gameService
        ))
    }
}
```

Wired through `BattleFightRouteView` instead of `SessionRouteView`.

---

## ViewModel Structure

**Path:** `Packages/elf_Kit/Sources/UILayer/{Feature}/{Feature}ViewModel.swift`

> **Rule:** Dependencies are **never** passed through `init` except for session-scoped state (`gameService`) or screen-scoped state (`battle`, `activity`). All stateless services come from `@Dependency`.

### Session-bound VM

```swift
import Dependencies

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

    public var canHunt: Bool {
        gameService.actionPoints.current >= huntCost && !isHunting
    }

    public init(gameService: any GameService) {
        self.gameService = gameService
    }

    public func startHunt() -> Battle? { /* ... */ }
}
```

### App-scoped VM

```swift
@MainActor
@Observable
public final class MainMenuViewModel {

    @ObservationIgnored
    @Dependency(\.gameRepository) private var gameRepository

    public private(set) var hasSavedGame: Bool = false

    public init() {}

    public func refreshSavedGameState() {
        hasSavedGame = gameRepository.hasAnySave()
    }
}
```

`@ObservationIgnored` is mandatory on every `@Dependency` field in an `@Observable` class — see `threading-model.md` § "@ObservationIgnored for dependencies".

---

## Presentation Types

Types that live between ViewModel and View. Two categories with different rules:

### Two concepts

- **Display DTO** — immutable projection of domain data for rendering. Built by the ViewModel, consumed by the View. Flat structure with render-ready fields (`imageName: String`, pre-formatted strings, `canComplete: Bool`).
- **View State** — local UI state. Usually mutable, stored as a ViewModel property. Enum for tab/stage; struct/class for multi-field UI state.

### Rules

| Rule | Description |
|------|-------------|
| Location | Feature presentation types live in `Packages/elf_Kit/Sources/UILayer/{Feature}/`. Never in `DataLayer` or `elf_SwiftUI` (design system only). |
| File grouping | One file `{Feature}DisplayModels.swift` per feature contains all presentation types of that feature. Exception: a single enum ≤~20 lines, purely view-state, stays inline in the VM file. |
| DTO suffix | `*Display`. Do not use `*DisplayData`, `*DisplayItem`, `*ListItem`. |
| Numeric attribute bag suffix | `*Attributes` (e.g., `WeaponAttributes`, `CraftItemAttributes`). |
| View-state enum suffix | Pick by meaning: `Mode`, `Tab`, `Stage`, `Phase`, `Step`, `Selection`. Do not force a uniform suffix — semantics differ. |
| View-state struct/class suffix | `*State` (e.g., `HeroConfigurationState`, `ItemSelectorState`). |
| DTO conformances | `Sendable + Equatable` — always. `Identifiable` — only if used in `ForEach`, with a **stable** `id` (from domain, not `UUID()` on each mapping). `Hashable` — only when actually used as a dict key, `Set` element, or `NavigationDestination` value. `Codable` — do not add (DTOs are not persisted). |
| When NOT to create a DTO | If the View consumes a single domain value as-is and that value is already `Sendable + Equatable`, pass the domain value directly. Wrapping for wrapping's sake is an anti-pattern. Create a DTO when the VM **formats, combines, or filters** domain data for the view. |

### Example

```swift
// Display DTO — in UILayer/Hunt/HuntDisplayModels.swift
public struct MonsterDisplay: Identifiable, Equatable, Sendable {
    public let id: UUID                 // from the domain Monster
    public let title: String
    public let imageName: String
    public let drops: [DropDisplay]
}

// View State enum — inline at the top of UILayer/Calendar/CalendarViewModel.swift
public enum ViewMode: Int, CaseIterable, Sendable {
    case line, grid
    var title: String { ... }
    var iconName: String { ... }
}
```

---

## Navigation

### AppRouter
```swift
@Observable
@MainActor
final class AppRouter {
    var navigationPath = NavigationPath()
    var presentedModal: ModalRoute?

    func navigate(to route: AppRoute, removingPrevious count: Int = 0)
    func pop()
    func popToRoot()
    func popToGameDay()       // pops everything above GameDayScreen
    func presentModal(_ modal: ModalRoute)
    func dismissModal()
}
```

`popToGameDay()` assumes `.gameSession` always sits at the bottom of `navigationPath` (root is `MainMenuScreen`, outside the path). Used by `GameDayHeader` to auto-return from sub-screens (Hunt/Farm/Quest/…) when `advanceToNextDay()` lands on a non-`.normal` `DayType`.

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

Default recipe assumes a session-bound screen. For variants (no session, optional session) see notes at the bottom.

1. **Create the ViewModel** at `Packages/elf_Kit/Sources/UILayer/{Name}/{Name}ViewModel.swift`. Use `@MainActor @Observable`. The only init parameter is `gameService` (session state); stateless services come from `@Dependency`.
```swift
import Dependencies

@MainActor
@Observable
public final class NewScreenViewModel {

    private let gameService: any GameService

    @ObservationIgnored
    @Dependency(\.someService) private var someService

    public init(gameService: any GameService) {
        self.gameService = gameService
    }
}
```

2. **Add a factory** to `GameSessionModel` (`Packages/elf_Kit/Sources/UILayer/GameSession/GameSessionModel.swift`):
```swift
public func makeNewScreenViewModel() -> NewScreenViewModel {
    NewScreenViewModel(gameService: gameService)
}
```

3. **Create the Screen** at `Packages/elf_iOS/Sources/Screens/{Name}Screen/{Name}Screen.swift`:
```swift
import elf_Kit
import elf_SwiftUI
import SwiftUI

struct NewScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: NewScreenViewModel

    init(session: GameSessionModel) {
        self._viewModel = State(initialValue: session.makeNewScreenViewModel())
    }

    var body: some View {
        // UI
    }
}
```

4. **Add the route** in `AppRoute.swift` and wire it through `SessionRouteView`:
```swift
case newScreen
// in AppRoute.view():
case .newScreen:
    SessionRouteView { NewScreen(session: $0) }
```

5. **Add a `#Preview`** that bootstraps DI and a preview session (canonical: `HuntScreen.swift`).

### Variants

- **Not session-bound** (e.g., main menu): no-arg `init()`, build the VM directly (`MainMenuViewModel()`); skip step 2 and the `SessionRouteView` wrapper.
- **Optional session** (e.g., battle screens reachable from a dev flow): take `init(thing:, session: GameSessionModel?)`; wire via a dedicated route adapter (see `BattleFightRouteView`).

---

## File Structure

```
Packages/elf_iOS/Sources/
├── Screens/
│   ├── {ScreenName}Screen/
│   │   ├── {ScreenName}Screen.swift
│   │   └── Components/
├── DependencyInjection/
│   └── DependencyBootstrap.swift
├── Coordinator/
│   └── AppCoordinator.swift
└── Navigation/
    ├── AppRouter.swift
    ├── AppRoute.swift
    ├── ModalRoute.swift
    └── SessionRouteView.swift

Packages/elf_Kit/Sources/UILayer/
├── GameSession/
│   └── GameSessionModel.swift
└── {Feature}/
    ├── {Feature}ViewModel.swift
    └── {Feature}DisplayModels.swift

Packages/elf_Kit/Sources/DataLayer/.../{Service}/
├── {Service}.swift                 # protocol
├── Implementation/
│   └── Default{Service}.swift
└── {Service}+Dependency.swift      # DependencyKey + DependencyValues extension
```

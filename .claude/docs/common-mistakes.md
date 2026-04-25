# Common Mistakes

## SwiftUI (iOS 17+)

| ❌ Don't Use | ✅ Use Instead |
|-------------|----------------|
| `ObservableObject` | `@Observable` |
| `@Published` | Regular properties in @Observable |
| `@StateObject` | `@State` (with @Observable) |
| `@ObservedObject` | `@State` or `@Bindable` |
| `NavigationView` | `NavigationStack` |
| `NavigationLink(destination:)` | `navigationDestination(for:)` |
| `.onAppear { Task { } }` | `.task { }` |
| `@Environment(\.presentationMode)` | `@Environment(\.dismiss)` |

### Background and Safe Area
```swift
// ❌ Ignores safe area (background extends beyond screen edges)
.background(Color.gray)

// ✅ Respects safe area
.background {
    Color.gray
}
```

---

## Architecture Mistakes

### Passing services through ViewModel init
```swift
// ❌ Every dep through init — leaks DI plumbing into every call site
public init(
    gameService: any GameService,
    damageService: any DamageService,
    progressionService: any ProgressionService,
    monsterRepository: any MonsterRepository
) { ... }

// ✅ Only session-scoped state through init; stateless services via @Dependency
@MainActor
@Observable
public final class HuntViewModel {
    private let gameService: any GameService

    @ObservationIgnored
    @Dependency(\.monsterRepository) private var monsterRepository

    @ObservationIgnored
    @Dependency(\.progressionService) private var progressionService

    public init(gameService: any GameService) {
        self.gameService = gameService
    }
}
```

### `@unchecked Sendable` on a final class with `@Dependency`
```swift
// ❌ The @Dependency property wrapper is not Sendable, so you reach for @unchecked
public final class ElfFooService: FooService, @unchecked Sendable {
    @Dependency(\.barService) private var barService
}

// ✅ Typed-wrapper pattern — Sendable for free
public final class ElfFooService: FooService {
    private let _barService = Dependency(\.barService)
    private var barService: any BarService { _barService.wrappedValue }
}
```

### Bypassing `GameSessionModel` for session-bound VMs
```swift
// ❌ Building a session VM yourself in a Screen (forces force-unwrap on optional session)
let vm = HuntViewModel(gameService: coordinator.sessionModel!.gameService)

// ✅ Always go through the factory; SessionRouteView already unwraps the optional
init(session: GameSessionModel) {
    self._viewModel = State(initialValue: session.makeHuntViewModel())
}
```

### Business Logic in ViewModel
```swift
// ❌ ViewModel contains business logic
class MyViewModel {
    func calculateDamage() -> Int {
        // complex calculations here
    }
}

// ✅ ViewModel uses services
@MainActor
@Observable
class MyViewModel {
    @ObservationIgnored
    @Dependency(\.damageService) private var damageService

    func calculateDamage() -> Int {
        damageService.calculate(...)
    }
}
```

### Static/Singleton
```swift
// ❌ Avoid static
class Service {
    static let shared = Service()
}

// ✅ Dependency Injection via swift-dependencies
@ObservationIgnored
@Dependency(\.someService) private var someService

// Or, for session-bound state, via GameSessionModel factories
init(session: GameSessionModel) {
    self._viewModel = State(initialValue: session.makeXxxViewModel())
}
```

---

## Project-Specific Rules

### Orientation
App supports **landscape orientation only**.
Keep this in mind when creating layouts.

### Hardcoded Colors, Fonts, and Sizes in UI
```swift
// ❌ Magic numbers and raw colors in views
Color.black.opacity(0.5)
Font.system(size: 24, weight: .semibold)
.frame(width: 300, height: 200)

// ✅ Use design tokens from elf_SwiftUI/Sources/DesignSystem/
ElfColors.Background.overlayMedium
ElfFonts.Component.sectionTitle
.frame(width: ElfSizing.FishingProgress.width, height: ElfSizing.FishingProgress.height)
```
All UI styles (colors, fonts, spacing, sizing) must come from `elf_SwiftUI/Sources/DesignSystem/`. If a token doesn't exist, add it there first.

### Force Unwrap
```swift
// ❌ Never
let item = items.first!

// ✅ Safe unwrap
guard let item = items.first else { return }
```

### Combine vs async/await
```swift
// ❌ Don't use Combine for new code
import Combine

// ✅ Use async/await
func loadData() async throws -> Data
```

---

## Memory & Concurrency

### Retain Cycle
```swift
// ❌ Retain cycle
onComplete = {
    self.doSomething()
}

// ✅ Weak self
onComplete = { [weak self] in
    self?.doSomething()
}
```

### MainActor
```swift
// ❌ Without MainActor
@Observable
class ViewModel {
    var items: [Item] = []
}

// ✅ With MainActor
@MainActor
@Observable
class ViewModel {
    var items: [Item] = []
}
```

---

## Presentation Types

### DisplayDTO in the wrong layer
```swift
// ❌ Display DTO in DataLayer
// Packages/elf_Kit/Sources/DataLayer/Model/Inventory/InventoryDisplayItem.swift
public struct InventoryDisplayItem { ... }

// ✅ Display DTO in UILayer, co-located with the VM that builds it
// Packages/elf_Kit/Sources/UILayer/Inventory/InventoryDisplayModels.swift
public struct InventoryItemDisplay { ... }
```

### Inconsistent suffixes for one concept
```swift
// ❌ Six suffixes for the same idea
MonsterDisplayData, QuestDisplayData     // DisplayData
InventoryDisplayItem                      // DisplayItem
CraftRecipeListItem                       // ListItem
WeaponDetails, ArmorDetails               // Details

// ✅ One suffix — *Display — for presentation DTOs
MonsterDisplay, QuestDisplay, InventoryItemDisplay, CraftRecipeDisplay

// ✅ *Attributes — for numeric stat bags
WeaponAttributes, ArmorAttributes, CraftItemAttributes
```

### Conformances "just in case"
```swift
// ❌ Adding Hashable / Codable without a reason
public struct MonsterDisplay: Identifiable, Hashable, Codable, Sendable { ... }

// ✅ Only what's actually used
public struct MonsterDisplay: Identifiable, Equatable, Sendable { ... }
// Add Hashable only when used as dict key / Set element / NavigationDestination.
// DTOs are not persisted → never Codable.
```

### Unstable id in DTO mapping
```swift
// ❌ New UUID on every rebuild → SwiftUI re-renders the whole list
items.map { MonsterDisplay(id: UUID(), title: $0.name, ...) }

// ✅ id comes from the domain → stable diff
items.map { MonsterDisplay(id: $0.id, title: $0.name, ...) }
```

See `project-architecture.md` → **Presentation Types** for the full convention.

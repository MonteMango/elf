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

### View → GameSession Bypass (View mutating GameSession/DungeonSession directly)
```swift
// ❌ View reaches past its ViewModel into session state directly
struct HuntView: View {
    let session: GameSessionModel

    var body: some View {
        Button("Flee") {
            session.dungeonSession?.endRun() // View mutates session state directly
        }
    }
}

// ✅ View only ever talks to its own ViewModel; the ViewModel owns the session call
@MainActor
@Observable
final class HuntViewModel {
    private let session: GameSessionModel

    init(session: GameSessionModel) {
        self.session = session
    }

    func flee() {
        session.dungeonSession?.endRun()
    }
}

struct HuntView: View {
    let viewModel: HuntViewModel

    var body: some View {
        Button("Flee") {
            viewModel.flee()
        }
    }
}
```
A View that mutates `GameSessionModel`/`DungeonSession` directly breaks the MVVM boundary: it duplicates
state-change logic outside the ViewModel, makes that logic untestable without standing up a View, and
lets two code paths (View and ViewModel) mutate the same session state independently. Route every
session mutation through the ViewModel.

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
// or throw excwption (insted of just return)
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

### Assigning `nil` to a dictionary keyed by an Optional value type removes the key, not the value
For `[Key: Value?]`, subscript-assigning the literal `nil` removes the key entirely — it does **not**
store `.some(nil)` (a key present with a nil value). This is a real bug, found in review of
`structured-task-cancellation`: `ElfWeaponValidator` cleared a slot via `dict[slot] = nil`, and code
merging the result by iterating `dict`'s own keys silently skipped the cleared slot because it was no
longer in the dictionary at all.
```swift
var items: [Slot: ItemID?] = [.weapons: someId, .shields: shieldId]

// ❌ Removes `.shields` from `items` — does not store "shields is now nil"
items[.shields] = nil
// items == [.weapons: someId]  — `.shields` key is gone

// If downstream code merges by iterating `items`' own keys, a cleared slot
// is invisible to it — the old value silently survives.
for (slot, value) in items { merge(slot, value) }   // `.shields` never visited

// ✅ If "key present, value nil" is the intent, wrap explicitly
items.updateValue(Optional<ItemID>.none, forKey: .shields)
// items == [.weapons: someId, .shields: nil]  — `.shields` key still present

// ✅ Downstream code that must distinguish "absent" from "explicitly cleared"
// should merge over the union of both dictionaries' keys, not just one side's
for slot in Set(before.keys).union(after.keys) {
    let resolved = after[slot] ?? nil   // absent-in-`after` reads the same as present-with-nil
    // ...
}
```

### Cancel-and-replace `Task` per key: a cross-key side effect decided from the pre-`await` snapshot can go stale
When a `Task<Void, Never>?` handle is scoped *per key* (e.g. one handle per dictionary slot, so an
edit to key A doesn't cancel an in-flight edit to key B), a Task that snapshots the whole dictionary
before its `await` and later applies a decision that touches a key it doesn't own (a cross-key side
effect, e.g. "selecting a two-handed weapon must clear the shield slot") can act on a value that
another concurrent, independent Task for that other key already overwrote while the first Task was
suspended. This is a real bug, found in review of `structured-task-cancellation`: the snapshot-based
compare-before-write let an older Task's side effect silently drop or invalidly re-apply a newer,
already-landed selection for the key it didn't own.
```swift
// ❌ Compares/writes against the pre-`await` snapshot, even for a key this
// Task doesn't own — a concurrent Task for that other key may have already
// written something newer while this Task was suspended.
let snapshot = state.items
let result = await validate(current: snapshot)
for key in Set(snapshot.keys).union(result.keys) {
    guard (snapshot[key] ?? nil) != (result[key] ?? nil) else { continue }
    state.items[key] = result[key] ?? nil
}

// ✅ Re-check against the live state before writing; if it diverged from the
// snapshot, re-run the decision against the live state and use that as both
// the merge baseline and the source of truth for keys this Task doesn't own.
var validated = result
var baseline = snapshot
let live = state.items
if live != snapshot {
    validated = await validate(current: live)
    baseline = live
}
for key in Set(baseline.keys).union(validated.keys) {
    guard (baseline[key] ?? nil) != (validated[key] ?? nil) else { continue }
    state.items[key] = validated[key] ?? nil
}
```
Per-key handles fix the *spurious cancellation* problem (an edit to key B no longer cancels an
in-flight edit to key A) but reintroduce a *stale cross-key decision* problem unless the write path
re-checks live state before applying anything that isn't scoped to the Task's own key.

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

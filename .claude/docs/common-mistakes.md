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

### Screen without ScreenContent
```swift
// ❌ Everything in one file
struct MyScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container
    @State private var viewModel: MyViewModel // DI and UI mixed
}

// ✅ Separate into two files
// MyScreen.swift — DI only
struct MyScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container
    var body: some View {
        MyScreenContent(viewModel: container.makeMyViewModel())
    }
}

// MyScreenContent.swift — UI implementation
struct MyScreenContent: View {
    @State private var viewModel: MyViewModel
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
class MyViewModel {
    private let damageService: DamageService

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

// ✅ Dependency Injection via container
@Environment(ElfAppDependencyContainer.self) private var container
let vm = container.makeViewModel()
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

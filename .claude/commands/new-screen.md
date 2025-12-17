Create a new screen with the standard Screen/ScreenContent pattern.

Arguments: $ARGUMENTS (screen name, e.g., "Inventory" or "Shop")

Steps:
1. Create ViewModel in `Packages/elf_Kit/Sources/UILayer/{Name}/{Name}ViewModel.swift`
2. Create Screen in `Packages/elf_iOS/Sources/Screens/{Name}Screen/{Name}Screen.swift`
3. Create ScreenContent in `Packages/elf_iOS/Sources/Screens/{Name}Screen/{Name}ScreenContent.swift`
4. Add factory method to `ElfAppDependencyContainer.swift`
5. Add route to `AppRoute.swift`

Follow patterns from `.claude/docs/project-architecture.md`

Use this template for each file:

### ViewModel
```swift
import Foundation

@Observable
@MainActor
public final class {Name}ViewModel {

    public init() {
    }
}
```

### Screen
```swift
import SwiftUI

internal struct {Name}Screen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    internal var body: some View {
        {Name}ScreenContent(viewModel: container.make{Name}ViewModel())
    }
}
```

### ScreenContent
```swift
import SwiftUI

internal struct {Name}ScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: {Name}ViewModel

    internal init(viewModel: {Name}ViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    internal var body: some View {
        Text("{Name} Screen")
    }
}
```

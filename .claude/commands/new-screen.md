Create a new screen using the single-file Screen pattern with swift-dependencies.

Arguments: $ARGUMENTS (screen name, e.g., "Inventory" or "Shop")

## Default: session-bound screen

Steps:
1. Create ViewModel: `Packages/elf_Kit/Sources/UILayer/{Name}/{Name}ViewModel.swift`
2. Add factory method to `GameSessionModel` (`Packages/elf_Kit/Sources/UILayer/GameSession/GameSessionModel.swift`)
3. Create Screen: `Packages/elf_iOS/Sources/Screens/{Name}Screen/{Name}Screen.swift`
4. Add a case to `AppRoute.swift` and wire it via `SessionRouteView` in `AppRoute.view()`

Follow patterns from `.claude/docs/project-architecture.md` (Screen Pattern, ViewModel Structure) and `.claude/docs/dependency-injection.md`.

### ViewModel template

```swift
import Dependencies
import Foundation

@MainActor
@Observable
public final class {Name}ViewModel {

    private let gameService: any GameService

    // Stateless services via @Dependency. Each one needs @ObservationIgnored.
    // @ObservationIgnored
    // @Dependency(\.someService) private var someService

    public init(gameService: any GameService) {
        self.gameService = gameService
    }
}
```

### GameSessionModel factory

```swift
public func make{Name}ViewModel() -> {Name}ViewModel {
    {Name}ViewModel(gameService: gameService)
}
```

### Screen template

```swift
import elf_Kit
import elf_SwiftUI
import SwiftUI

struct {Name}Screen: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: {Name}ViewModel

    init(session: GameSessionModel) {
        self._viewModel = State(initialValue: session.make{Name}ViewModel())
    }

    var body: some View {
        Text("{Name} Screen")
    }
}
```

### Route wiring (in `AppRoute.view()`)

```swift
case .{name}:
    SessionRouteView { {Name}Screen(session: $0) }
```

### Preview

```swift
#if DEBUG
#Preview {
    @Previewable @State var coordinator: AppCoordinator?
    @Previewable @State var router = AppRouter()

    if let coordinator, let session = coordinator.sessionModel {
        NavigationStack(path: $router.navigationPath) {
            {Name}Screen(session: session)
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

## Variant: not session-bound (main menu / character creation)

If the screen runs before a game session exists:
- ViewModel: no-arg `public init()`. All deps via `@Dependency`.
- Screen: no-arg `init()`, build the VM directly: `_viewModel = State(initialValue: {Name}ViewModel())`.
- Skip the `GameSessionModel` factory (step 2). In the route, do not wrap with `SessionRouteView` — instantiate the screen directly.

## Variant: optional session (e.g., battle screens reachable from a dev flow)

- Screen: `init(thing: Thing, session: GameSessionModel?)`. ViewModel takes `gameService: (any GameService)?`.
- Wire via a dedicated route adapter (see `BattleFightRouteView` for the canonical pattern).

# SwiftUI Patterns (iOS 17+)

## @Observable (replaces ObservableObject)

```swift
// ❌ Old way (don't use)
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
}

struct MyView: View {
    @StateObject var vm = ViewModel()
}

// ✅ iOS 17+ (use this)
@Observable
class ViewModel {
    var items: [Item] = []
}

struct MyView: View {
    @State var vm = ViewModel()
}
```

## Navigation

```swift
// ❌ Deprecated
NavigationView {
    List { }
}

// ✅ iOS 16+
NavigationStack {
    List { }
}

// With path for programmatic navigation
@State private var path = NavigationPath()

NavigationStack(path: $path) {
    List { }
        .navigationDestination(for: Item.self) { item in
            DetailView(item: item)
        }
}
```

## Environment

```swift
// ❌ Old way
@Environment(\.presentationMode) var presentationMode
presentationMode.wrappedValue.dismiss()

// ✅ iOS 15+
@Environment(\.dismiss) var dismiss
dismiss()
```

## Async Work

```swift
// ❌ Don't use
.onAppear {
    Task {
        await loadData()
    }
}

// ✅ Use this
.task {
    await loadData()
}

// With cancellation on disappear
.task(id: itemId) {
    await loadData(for: itemId)
}
```

## State Management

```swift
// @State — local View state
@State private var isLoading = false

// @Binding — two-way binding
func childView(isPresented: Binding<Bool>)

// @Bindable — for @Observable objects
@Bindable var vm: ViewModel
TextField("Name", text: $vm.name)

// @Environment — for system values and DI
@Environment(\.dismiss) var dismiss
@Environment(GameService.self) var gameService
```

## Landscape Layout

```swift
// Check orientation
GeometryReader { geometry in
    let isLandscape = geometry.size.width > geometry.size.height

    if isLandscape {
        HStack { /* landscape layout */ }
    } else {
        VStack { /* portrait layout */ }
    }
}

// Safe area for landscape
.ignoresSafeArea(.container, edges: .horizontal)
```

## Actors and MainActor

```swift
// ViewModel must be @MainActor
@Observable
@MainActor
class GameViewModel {
    var state: GameState = .idle

    func loadData() async {
        state = .loading
        let data = await dataService.fetch()
        state = .loaded(data)
    }
}
```

## ViewModels with Existential Types

ViewModels use `any Protocol` (existential types) for the session-scoped state passed through `init`. Stateless services come from `@Dependency` and don't appear in the init signature. Existentials are simpler than generics and safe with `@Observable`.

```swift
import Dependencies

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

### Factory Methods

Session-bound ViewModels are constructed by `GameSessionModel`. Because `gameService` is non-optional on the session, no runtime guard is needed.

```swift
// In Packages/elf_Kit/Sources/UILayer/GameSession/GameSessionModel.swift
public func makeHuntViewModel() -> HuntViewModel {
    HuntViewModel(gameService: gameService)
}
```

### Usage in Screen

```swift
struct HuntScreen: View {
    @State private var viewModel: HuntViewModel

    init(session: GameSessionModel) {
        self._viewModel = State(initialValue: session.makeHuntViewModel())
    }
}
```

> See `dependency-injection.md` for the full DI story (declaring deps, both injection styles, app bootstrap, tests, previews).

## AsyncImage

```swift
AsyncImage(url: url) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
    case .failure:
        Image(systemName: "photo")
    @unknown default:
        EmptyView()
    }
}
```

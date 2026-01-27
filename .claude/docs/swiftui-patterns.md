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

ViewModels use `any Protocol` (existential types) for dependencies. This is simpler than generics and works safely with `@Observable`.

```swift
@Observable
@MainActor
public final class HuntViewModel {
    private let gameService: any GameService
    private let monsterRepository: any MonsterRepository

    public init(
        gameService: any GameService,
        monsterRepository: any MonsterRepository
    ) {
        self.gameService = gameService
        self.monsterRepository = monsterRepository
    }
}
```

### Factory Methods

```swift
// In ElfAppDependencyContainer.swift
@MainActor
public func makeHuntViewModel() -> HuntViewModel {
    guard let gameService = activeGameService else {
        fatalError("No active game session.")
    }
    return HuntViewModel(
        gameService: gameService,
        monsterRepository: self.monsterRepository,
        // ...
    )
}
```

### Usage in ScreenContent

```swift
@State private var viewModel: HuntViewModel

init(viewModel: HuntViewModel) {
    self._viewModel = State(initialValue: viewModel)
}
```

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

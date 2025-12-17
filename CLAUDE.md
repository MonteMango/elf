# Elfy - iOS RPG Game

## Tech Stack
- **Platform:** iOS 17+
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Architecture:** MVVM
- **Concurrency:** async/await (not Combine)

## Build Commands
```bash
# Build
xcodebuild -scheme elf -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Tests
swift test --package-path Packages/elf_Kit
```

## Orientation
App supports **landscape orientation only**.

## Code Rules
- Avoid using `static` — use Dependency Injection
- Build and test only for iOS (not macOS)

---

## SwiftUI Rules (iOS 17+)

### Use
- `@Observable` instead of ObservableObject
- `@State` with @Observable instead of @StateObject
- `NavigationStack` instead of NavigationView
- `.task { }` instead of .onAppear { Task { } }
- `@Environment(\.dismiss)` instead of presentationMode
- `@MainActor` on all ViewModels

### Don't Use
- ObservableObject, @Published
- @StateObject, @ObservedObject
- NavigationView
- Force unwrap (!)
- Combine for new code

---

## Documentation
- **Architecture:** `.claude/docs/project-architecture.md`
- **SwiftUI patterns:** `.claude/docs/swiftui-patterns.md`
- **Persistence:** `.claude/docs/persistence-patterns.md`
- **Common mistakes:** `.claude/docs/common-mistakes.md`
- **Game design:** `.claude/docs/game-design.md`

Before writing code, check `.claude/docs/` for current patterns.

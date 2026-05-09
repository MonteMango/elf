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
xcodebuild test -scheme elf_Kit -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Dead code detection (requires: brew install peripheryapp/periphery/periphery)
./scripts/periphery-scan.sh              # all packages
./scripts/periphery-scan.sh elf_Kit      # single package
```

**Note:** Always run unit tests after making code changes to ensure nothing is broken.

## Orientation
App supports **landscape orientation only**.

## Code Rules
- Never use `static` keyword in code. Only use it when there is no other option — prefer Dependency Injection
- Build and test only for iOS (not macOS)

## Save / Persistence Policy
While the project is in active early development, **save-format migrations are NOT a concern**. If a refactor needs to change the shape of `Game`, `GameSaveData`, or any persisted structure, change it freely — old save files do not need to keep loading. No migration code, no version bumps, no compatibility shims. Existing saves on dev devices can be wiped between runs. This policy lifts once the game ships its first public build.

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

**Read before specific tasks:**

| Task | Read first |
|------|------------|
| Adding new screen | `project-architecture.md` — Screen Pattern; `dependency-injection.md` |
| Creating ViewModel or Service | `project-architecture.md` — Business Logic Rules |
| Adding a service / dependency / using @Dependency | `dependency-injection.md` |
| Writing SwiftUI views | `swiftui-patterns.md` — @Observable, .task{}, @Bindable |
| Saving/loading game data | `persistence-patterns.md` — ID-Reference pattern, migrations |
| Creating new types/models | `type-driven-design.md` — Make impossible states unrepresentable |
| Creating presentation types (Display DTO / View State) | `project-architecture.md` — Presentation Types section |
| Working with async/actors | `threading-model.md` — @MainActor, actors, thread safety |
| Using colors, fonts, spacing | `project-architecture.md` — Design System section |
| Unsure about something | `common-mistakes.md` — check anti-patterns first! |
| Game mechanics questions | `game-design.md` — Combat, Activities, Attributes |
| Attributes, fight styles, Endurance/EP system | `attributes.md` — single source of truth |
| Driving the iOS Simulator with RocketSim | `rocketsim-usage.md` — landscape→portrait coord transform |
| Generating game art via Leonardo AI (portraits, backgrounds, icons) | `leonardo-ai-prompts.md` — prompt structure, Anime XL specifics, project seed, working examples |

**Quick reference:**
- All docs: `.claude/docs/`
- Design tokens: `elf_SwiftUI/Sources/DesignSystem/`

**Important:** All UI styles (colors, fonts, spacing, sizing) are in `elf_SwiftUI/Sources/DesignSystem/`. Do NOT create local style constants in `elf_iOS` - extend the central design system instead.

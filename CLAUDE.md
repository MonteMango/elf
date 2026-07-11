# Elfy - iOS RPG Game

## Tech Stack
- **Platform:** iOS 18+
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Architecture:** MVVM
- **Concurrency:** async/await (not Combine)
- **Dependency Injection:** swift-dependencies (pointfree) — `@Dependency`, see `dependency-injection.md`

## Project Structure
Xcode project `elf.xcodeproj` + 3 local SPM packages under `Packages/`:

| Module | Path | Role |
|--------|------|------|
| App target | `elf/` | Entry point (`ElfApp.swift`), Info.plist, Assets |
| `elf_Kit` | `Packages/elf_Kit/` | Domain & logic — `DataLayer` (services, models) + `UILayer`. Unit-tested package |
| `elf_iOS` | `Packages/elf_iOS/` | iOS composition — Coordinator, DependencyInjection, Navigation, Screens, Platform |
| `elf_SwiftUI` | `Packages/elf_SwiftUI/` | Design system & reusable UI — DesignSystem, Components, ButtonStyles, Utilities |

## Build Commands
```bash
# Build
xcodebuild -scheme elf -destination 'platform=iOS Simulator,name=iPhone 17' build

# Tests
xcodebuild test -scheme elf_Kit -destination 'platform=iOS Simulator,name=iPhone 17'

# Lint (run after code changes)
swiftlint --quiet
```

**Note:** Always run unit tests after making code changes to ensure nothing is broken.

## Orientation
App supports **landscape orientation only**.

## Code Rules
- Never use `static` keyword in code. Only use it when there is no other option — prefer Dependency Injection
- Build and test only for iOS (not macOS)

## Git Policy
- **Never make git commits.** Only the user (Vitalii Lytvynov) commits. Write/edit files as needed, but do not run `git commit` (or `git push`) — stage or leave changes as-is and let the user commit when ready. This applies to every workflow, including multi-step tools/skills whose default protocol calls for per-step commits (e.g. SDD skills) — skip the commit step and continue with the rest of the work.

## Save / Persistence Policy
While the project is in active early development, **save-format migrations are NOT a concern**. If a refactor needs to change the shape of `Game`, `GameSaveData`, or any persisted structure, change it freely — old save files do not need to keep loading. No migration code, no version bumps, no compatibility shims. Existing saves on dev devices can be wiped between runs. This policy lifts once the game ships its first public build.

---

## SwiftUI Rules (iOS 18+)

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
| Creating new types/models | `model-organization.md` — which Model group it belongs in (Catalog / RuntimeDomain / OwnedItems / Persistence / …); `type-driven-design.md` — Make impossible states unrepresentable |
| Creating presentation types (Display DTO / View State) | `project-architecture.md` — Presentation Types section |
| Working with async/actors | `threading-model.md` — @MainActor, actors, thread safety |
| Using colors, fonts, spacing | `project-architecture.md` — Design System section |
| Unsure about something | `common-mistakes.md` — check anti-patterns first! |
| Game mechanics questions | `game-design.md` — Combat, Activities, Attributes, Day Types |
| Working on dungeons (Dungeon Day, runs, party of 5) | `dungeon-design.md` — dungeon structure, `DungeonSession`/`DungeonScreen`, run save & restore, rewards ledger |
| Attributes, fight styles, Endurance/EP system | `attributes.md` — single source of truth (formulas, distributions, constants) |
| Combat balance, win-rate sweeps, tuning constants | `game-balance/README.md` — index; live task doc `balance-task-2026-05-26.md`; per-change simulation snapshots |
| Driving the iOS Simulator with RocketSim | `rocketsim-usage.md` — landscape→portrait coord transform |
| Generating game art via Leonardo AI (portraits, backgrounds, icons) | `leonardo-ai-prompts.md` — prompt structure, Anime XL specifics, project seed, working examples |
| Swift concurrency / language design rationale (best practices, Swift 6 migration) | `wwdc26/wwdc26-swift-group-lab.md` — WWDC26 Swift Group Lab Q&A, takeaways |
| Making an architectural decision, or understanding *why* code is shaped a certain way | `decisions/README.md` — ADR index + when/how to record one; ADRs `0001`–`0003` |
| Which skills / plugins / slash-commands are available (and how they're configured) | `skills-and-plugins.md` — full registry + file map |

**Update after changes:** After finishing any implementation or change, update the relevant docs in `.claude/docs/` in the same task — new patterns, changed commands/paths, new gotchas, added/removed services or screens. Keep the docs in sync with the code so the project stays well-documented. If a change makes an existing doc stale, fix it; if nothing changed, no update needed. For a significant design decision (API-shape change, choice between plausible approaches, reversal of a prior decision), also record an ADR in `decisions/` — see `decisions/README.md`.

**Quick reference:**
- All docs: `.claude/docs/`
- Design tokens: `Packages/elf_SwiftUI/Sources/DesignSystem/`

**Important:** All UI styles (colors, fonts, spacing, sizing) are in `Packages/elf_SwiftUI/Sources/DesignSystem/`. Do NOT create local style constants in `Packages/elf_iOS` - extend the central design system instead.

---

## Expert Skills

Three installed skills give deep help on Swift topics. **Invoke the matching skill when the task fits its scope** — including while running SDD flows (`/sdd:*`) in this session:

| Skill | Use for |
|-------|---------|
| `swift-concurrency` | async/await, actors, `Sendable`, `@MainActor`, data races, Swift 6 migration |
| `swift-testing-expert` | writing/refactoring Swift Testing suites (`#expect`/`#require`, traits, parameterized tests) |
| `swiftui-expert` | writing/reviewing SwiftUI: `@Observable` data flow, view invalidation/perf, list identity, animations |

**Reach:** skills run via the `Skill` tool, so only an agent that has that tool can invoke them — i.e. this main session (and `/sdd:implement` in single-agent mode). SDD's spawned sub-agents (`implementer`, `test-author`, `reviewer`, …) have a restricted tool set **without** `Skill`, so they cannot call these skills themselves. Guidance those sub-agents can reach lives in `.claude/docs/` (they can `Read`): `threading-model.md`, `swiftui-patterns.md`, `common-mistakes.md` — keep it current so the expertise reaches them there.

**Docs vs. skills — precedence (not either/or):**
- **`.claude/docs/` + CLAUDE.md rules are the always-on base** — project-specific truth (our threading model, DI patterns, real gotchas). Read them first; they are authoritative.
- **Expert skills are on-demand depth** — general Swift/SwiftUI/concurrency/testing best practice, invoked when a task is genuinely hard on that topic and the docs don't fully cover it.
- **On conflict, the project wins.** If a skill's general advice contradicts a project rule (`no static`, `async/await not Combine`, landscape-only, styles only in DesignSystem), follow the project — adapt the skill's pattern to our conventions, and if it's a new reusable pattern, capture it back into `.claude/docs/` (per *Update after changes*).

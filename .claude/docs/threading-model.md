# Threading Model

Guidelines for thread safety and concurrency in Elfy.

## Core Principles

1. **UI updates only on MainThread** - All `@Observable` state mutations must happen on MainThread
2. **Heavy computations off MainThread** - Battle simulations, calculations should run on background threads
3. **I/O operations use actors** - File operations use `actor` for thread-safe serialization

## When to Use What

### @MainActor

Use `@MainActor` for:
- **ViewModels** - Always. They hold UI state that SwiftUI observes
- **Methods that mutate @Observable state** - GameService state mutations
- **UI callbacks** - Button actions, navigation handlers

```swift
@MainActor
@Observable
public final class BattleViewModel {
    var playerHP: Int  // UI state - needs MainActor

    func onAttackTapped() {  // UI callback
        // ...
    }
}
```

Do NOT use `@MainActor` for:
- Pure calculation functions
- Data transformation
- Repository protocols
- Services that don't hold observable state

### actor

Use `actor` for:
- **I/O operations** - File read/write, database access
- **Shared mutable state** - Counters, caches that need thread-safe access

```swift
public actor FileGameRepository: GameRepository {
    func save(_ game: Game) async throws {
        // File I/O - actor serializes access
    }
}
```

### Sendable

Use `Sendable` for:
- **Immutable types** - Value types with no mutable state
- **Thread-safe services** - Services with only `let` properties

```swift
// Good - all properties are immutable
public final class ElfDamageService: DamageService, Sendable {
    private let distributionStrategy: StrengthDamageDistributionStrategy
    private let itemsRepository: ItemsRepository
}
```

Use `@unchecked Sendable` ONLY when:
- You've verified all properties are effectively immutable
- Add a comment explaining why it's safe

```swift
// MARK: - Sendable Conformance
// Thread-safe: All properties are let and initialized once
extension ElfDamageService: @unchecked Sendable {}
```

### async/await

Use `async` for:
- **Actual asynchronous work** - Network, file I/O, Task.sleep
- **Methods that call other async methods**
- **Parallel computation** - withTaskGroup

Do NOT use `async` for:
- Synchronous calculations (misleading API)
- Methods with no await inside

```swift
// BAD - no actual async work
func calculate() async -> Int {
    return 1 + 1  // This is synchronous!
}

// GOOD - actual async work
func fetchData() async throws -> Data {
    try await URLSession.shared.data(from: url)
}
```

## Debug Assertions

Use `ThreadingUtils.swift` to catch threading issues during development:

```swift
func heavyCalculation() {
    assertNotMainThread("This should run on background")
    // ... expensive work
}

@MainActor
func updateUI() {
    assertMainThread("UI updates must be on main thread")
    // ... UI work
}
```

## Common Patterns

### ViewModel calling service

```swift
@MainActor
public final class GameDayViewModel {
    private let gameService: GameService

    func onNextDay() {
        // Synchronous state mutation - OK on MainActor
        gameService.advanceToNextDay()

        // Async save - runs on background via actor
        Task {
            try await gameService.saveGame()
        }
    }
}
```

### Parallel computation

```swift
func runMultipleBattles(count: Int) async -> [BattleResult] {
    await withTaskGroup(of: BattleResult.self) { group in
        for _ in 0..<count {
            group.addTask {
                // Each battle runs in parallel on background threads
                await self.battleService.runBattle()
            }
        }
        return await group.reduce(into: []) { $0.append($1) }
    }
}
```

## Architecture Layers

| Layer | Threading | Notes |
|-------|-----------|-------|
| View | MainThread | SwiftUI manages this |
| ViewModel | @MainActor | Holds observable state |
| Service (state) | @MainActor | GameService, EquipmentService |
| Service (calc) | None | DamageService, CritService - thread-safe |
| Repository | actor | File I/O isolation |
| Model | Sendable | Value types, immutable |

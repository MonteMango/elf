---
id: T4
title: "Add session-aware BattleResult companion ViewModel + factory calling completeDungeonRun()"
layer: "app"
deps: ["T1"]
acs: ["AC-03", "AC-04", "AC-07"]
files_hint: ["Packages/elf_Kit/Sources/UILayer/BattleResult/", "Packages/elf_Kit/Sources/UILayer/GameSession/GameSession+ViewModelFactories.swift", "Packages/elf_Kit/Tests/elf_KitTests/UILayer/BattleResult/"]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T4 — Add session-aware BattleResult companion ViewModel + factory calling completeDungeonRun()

## Why

`BattleResultViewModel = ResultViewModel<T>` is a documented reusable, display-only generic type (fishing/foraging/battle) and must not gain a session dependency ([ADR-0001](../adr/0001-host-dungeon-completion-on-game-session.md) considered-and-rejected Option 3). A new small session-aware companion ViewModel owns the hero-death continuation path instead — [sad §5](../sad.md), [sad §6 Flow 2](../sad.md).

## What

Add a new session-aware companion ViewModel under `UILayer/BattleResult/`, delegating its finish method to `gameSession.completeDungeonRun()`. Add its factory method to `GameSession+ViewModelFactories.swift` (one `make*ViewModel()` per screen, per project convention). Do not modify the generic `ResultViewModel<T>` / `BattleResultViewModel` typealias.

## Definition of Done

- [ ] Unit test: the companion VM's finish method delegates to `gameSession.completeDungeonRun()`.
- [ ] `ResultViewModel<T>` / `BattleResultViewModel` typealias unchanged.
- [ ] Factory method added to `GameSession+ViewModelFactories.swift`, matching the existing `make*ViewModel()` naming convention.
- [ ] lint + vet clean

## Notes

Depends on T1. Blocks T11 (view wiring). `BattleResultScreen` will hold this companion VM alongside its existing generic display VM (precedent: `GameDayScreen` already holds `viewModel` + `inventoryViewModel`, per ADR-0001 consequences).

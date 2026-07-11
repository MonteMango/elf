---
id: T4
title: "Route the 9 confirmed raw-print sites through the logger dependency"
layer: "app"
deps: []
acs: ["AC-02"]
files_hint: [
  "Packages/elf_Kit/Sources/UILayer/CharacterCreation/CharacterCreationViewModel.swift",
  "Packages/elf_Kit/Sources/UILayer/GameDay/GameDayViewModel.swift",
  "Packages/elf_Kit/Sources/DataLayer/Services/Dungeon/Implementation/DefaultDungeonRewardCalculator.swift",
  "Packages/elf_Kit/Sources/DataLayer/Sessions/GameSession.swift"
]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T4 — Route the 9 confirmed raw-print sites through the logger dependency

## Why

[spec AC-02](../spec.md) / [sad §4 decision 4](../sad.md) (ADR-0004) requires ViewModel/service logging to go through `@Dependency(\.debugGameLogger)` / `\.debugBattleLogger` instead of raw `print`. 9 sites are confirmed current (2026-07-09 re-verification, [sad §4](../sad.md)).

## What

- `CharacterCreationViewModel.swift` — lines 201, 209, 219, 222 (×4). No logger dependency currently injected — add `@Dependency(\.debugGameLogger)` and swap all 4 calls.
- `GameDayViewModel.swift` — lines 93, 104, 176 (×3). Same: add the logger dependency, swap all 3 calls.
- `DefaultDungeonRewardCalculator.swift` — line 29 (×1). Add the logger dependency, swap the call.
- `GameSession.swift:487` — already has `debugGameLogger` injected; just swap this one call.

## Definition of Done

- [ ] 0 raw `print(` calls remain in the 4 files above
- [ ] each ViewModel/service without a prior logger dependency now has one, following the existing `{Service}+Dependency.swift` DI pattern
- [ ] existing tests pass unchanged

## Notes

Do this **before** T5 enables the SwiftLint `--strict` guard — otherwise the guard breaks the build on these exact sites.

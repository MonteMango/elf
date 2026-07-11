---
id: T5
title: "Add the SwiftLint raw-print custom_rules guard with the sad §8 allow-list"
layer: "wiring"
deps: ["T3", "T4"]
acs: ["AC-02"]
files_hint: [".swiftlint.yml"]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T5 — Add the SwiftLint raw-print custom_rules guard with the allow-list

## Why

[spec AC-02](../spec.md) / [ADR-0004](../adr/0004-swiftlint-rule-for-raw-print.md): a mechanical guard must reject a future raw `print(` where a logger is available, so the logging-consistency win survives future changes without manual vigilance (US-06).

## What

Add a `custom_rules` entry to `.swiftlint.yml` matching `print(` (allowing for `Swift.print(` evasion is an accepted limitation per [sad §11](../sad.md)), scoped by the allow-list from [sad §8](../sad.md) plus T3's two persistence-layer additions:
- `**/Services/Logging/Implementation/*Logger*.swift`
- `Packages/elf_SwiftUI/**`
- `Packages/elf_iOS/Sources/Screens/Dev/**`, `Packages/elf_Kit/Sources/UILayer/Dev/**`
- `Packages/elf_iOS/Sources/Diagnostics/**`
- `elf/ElfApp.swift`
- `Packages/elf_Kit/Sources/DataLayer/Persistence/Implementation/FileGameSaveStorage.swift`, `Packages/elf_Kit/Sources/DataLayer/Persistence/Model/DungeonRunRewardsSaveData.swift` (T3)

The rule's message explains in plain language that logging must go through the logger dependency, not a raw print.

## Definition of Done

- [ ] `swiftlint --strict` passes with 0 violations repo-wide
- [ ] a deliberately inserted `print(` in a non-allow-listed file (e.g. `GameDayViewModel.swift`) is blocked with the rule's explanatory message, then removed after confirming (AC-02's negative-path check)

## Notes

Depends on T3/T4 landing first — enabling this with unresolved print sites breaks the build for unrelated work.

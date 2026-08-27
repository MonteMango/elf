---
id: T9
title: "Wire GameDayScreen to call viewModel.startDungeonRun() instead of session.startDungeonSession(...)"
layer: "ui"
deps: ["T2"]
acs: ["AC-01", "AC-02", "AC-02b"]
files_hint: ["Packages/elf_iOS/Sources/Screens/GameDayScreen/GameDayScreen.swift"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T9 — Wire GameDayScreen to call viewModel.startDungeonRun()

## Why

`GameDayScreen.swift:131` calls `session.startDungeonSession(...)` directly from a button action closure — the first of the 4 View→session bypass points named in [spec §1](../spec.md) / [spec §7 KPI baseline](../spec.md). Reuses the design system and existing button — no new UI component.

## What

Replace the `GameDayScreen.swift:131` button action's direct `session.startDungeonSession(...)` call with `viewModel.startDungeonRun()` (from T2). Navigation (`router.navigate(...)`) stays in the View, per [sad §6 Flow 1](../sad.md).

## Definition of Done

- [ ] `GameDayScreen.swift` contains no direct `GameSession`/`DungeonSession` mutation.
- [ ] Build succeeds (`xcodebuild -scheme elf -destination 'platform=iOS Simulator,name=iPhone 17' build`).
- [ ] Happy-path manual/existing behavior unchanged (dungeon action still navigates to the dungeon screen).

## Notes

Depends on T2. This is a pure call-site swap — no new logic.

---
id: T2
title: "Add GameDayViewModel.startDungeonRun() with action-point debit"
layer: "app"
deps: []
acs: ["AC-01", "AC-02", "AC-02b", "AC-07"]
files_hint: ["Packages/elf_Kit/Sources/UILayer/GameDay/GameDayViewModel.swift", "Packages/elf_Kit/Tests/elf_KitTests/UILayer/GameDay/GameDayViewModel_StartDungeonRunTests.swift"]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T2 — Add GameDayViewModel.startDungeonRun() with action-point debit

## Why

Closes the documented gap in `prepareDungeonRun()`'s own doc-comment ("that happens when the run actually starts (follow-up PR)") — AP for a dungeon run is never actually debited today. Wraps the existing `prepareDungeonRun()` + `session.startDungeonSession(...)` choice and adds the `dungeonCost` debit — [spec §1](../spec.md), [sad §6 Flow 1](../sad.md), [AC-01/AC-02/AC-02b](../spec.md).

## What

Add `startDungeonRun()` to `GameDayViewModel.swift`. Happy path: `prepareDungeonRun()` succeeds (sufficient AP, dungeon+ally pool available) → `session.startDungeonSession(dungeonId, allyIds)` → debit `dungeonCost` action points exactly once. Failure path (insufficient AP, or no dungeon available): no session start, no AP debit, silent no-op — matches today's UX (no visible feedback is an accepted non-goal, spec §3).

## Definition of Done

- [ ] Unit test: sufficient AP + dungeon available → run starts, `dungeonCost` debited exactly once.
- [ ] Unit test: insufficient AP → no run started, zero AP debited.
- [ ] Unit test: dungeon pool empty (AC-02b) → no run started, zero AP debited.
- [ ] lint + vet clean

## Notes

Shares `GameDayViewModel.swift` with T8 (`exitGame()`) — overlapping `files_hint`, serialize the two tasks into the same lane.

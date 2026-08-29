---
id: T7
title: "Harden GameDayStateViewModel.advanceToNextDay() save ordering + logging"
layer: "app"
deps: []
acs: ["AC-05", "AC-06", "AC-06b", "AC-07"]
files_hint: ["Packages/elf_Kit/Sources/UILayer/GameDayState/GameDayStateViewModel.swift", "Packages/elf_Kit/Tests/elf_KitTests/UILayer/GameDayState/GameDayStateViewModel_AdvanceToNextDayTests.swift"]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T7 — Harden GameDayStateViewModel.advanceToNextDay() save ordering + logging

## Why

`advanceToNextDay()` is a documented exception that keeps its awaited catch-and-log form (not `saveInBackground()`) because it blocks the guarding `isAdvancingDay` flag until save completes — [spec §1 ¶3](../spec.md), [spec §6 NFR row 4](../spec.md), [sad §6 Flow 6](../sad.md), [sad §8 Blocking-guard save concept](../sad.md).

## What

In `GameDayStateViewModel.advanceToNextDay()`: call `session.awaitInFlightSave()` before the day-advance save (closes the race with an earlier background save, e.g. from the farm); replace the silently-dropped save-error path with an awaited catch-and-log via `DebugGameLogger`. Keep `isAdvancingDay` raised across both awaits, cleared at the single exit point reachable from both the success and the logged-failure branch.

## Definition of Done

- [ ] Unit test: `awaitInFlightSave()` is called before the day-advance save.
- [ ] Unit test: a save failure is caught and logged via `DebugGameLogger` instead of propagating; day-advance still completes.
- [ ] Unit test: `isAdvancingDay` guard covers the full duration of both awaits and clears on both success and failure.
- [ ] lint + vet clean

## Notes

Do not convert this to `saveInBackground()` — this is the documented blocking-guard exception (sad §8), not an oversight.

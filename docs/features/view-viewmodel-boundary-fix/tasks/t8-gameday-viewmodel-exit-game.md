---
id: T8
title: "Harden GameDayViewModel.exitGame() save ordering + logging"
layer: "app"
deps: []
acs: ["AC-05", "AC-06", "AC-06b", "AC-07"]
files_hint: ["Packages/elf_Kit/Sources/UILayer/GameDay/GameDayViewModel.swift", "Packages/elf_Kit/Tests/elf_KitTests/UILayer/GameDay/GameDayViewModel_ExitGameTests.swift"]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T8 — Harden GameDayViewModel.exitGame() save ordering + logging

## Why

`exitGame()` is a documented exception that keeps its awaited catch-and-log form because the caller awaits it before releasing the session — [spec §1 ¶3](../spec.md), [sad §6 Flow 5](../sad.md), [sad §8 Blocking-guard save concept](../sad.md), modeled on the existing `AppCoordinator.saveOnBackground()` pattern.

## What

In `GameDayViewModel.exitGame()`: call `session.awaitInFlightSave()` before the exit save (so a save the player just triggered can't still be running when the exit save happens); replace the silently-dropped save-error path with an awaited catch-and-log via `DebugGameLogger`. `exitGame()` must still complete (so the caller can proceed to `AppCoordinator.endGame()`) regardless of save outcome.

## Definition of Done

- [ ] Unit test: `awaitInFlightSave()` is called before the exit save.
- [ ] Unit test: a save failure is caught and logged via `DebugGameLogger` instead of propagating.
- [ ] Unit test: `exitGame()` completes on both the success and the logged-failure path.
- [ ] lint + vet clean

## Notes

Shares `GameDayViewModel.swift` with T2 (`startDungeonRun()`) — overlapping `files_hint`, serialize the two tasks into the same lane. Do not convert this to `saveInBackground()` — documented blocking-guard exception (sad §8).

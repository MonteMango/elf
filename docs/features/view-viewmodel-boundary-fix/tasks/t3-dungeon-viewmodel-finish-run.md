---
id: T3
title: "Route DungeonViewModel.finishRun() through GameSession.completeDungeonRun()"
layer: "app"
deps: ["T1"]
acs: ["AC-03", "AC-04", "AC-07"]
files_hint: ["Packages/elf_Kit/Sources/UILayer/Dungeon/DungeonViewModel.swift", "Packages/elf_Kit/Tests/elf_KitTests/UILayer/Dungeon/DungeonViewModel_FinishRunTests.swift"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T3 — Route DungeonViewModel.finishRun() through GameSession.completeDungeonRun()

## Why

`DungeonViewModel` already holds `gameSession` in its `init`, so it's the thin caller for the Finish-button path — [ADR-0001](../adr/0001-host-dungeon-completion-on-game-session.md), [sad §5](../sad.md) building-block decomposition, [sad §6 Flow 2](../sad.md).

## What

Add `finishRun()` to `DungeonViewModel.swift`, delegating to `gameSession.completeDungeonRun()`. Must stay a synchronous (non-`async`) method — the caller (T10, `DungeonScreen`) pops the route before calling it, and no `await` may sit between pop and session release (sad §8 sync-completion-with-fire-and-forget pattern).

## Definition of Done

- [ ] Unit test: `finishRun()` delegates to `gameSession.completeDungeonRun()` with no duplicated finish+save logic inline.
- [ ] `finishRun()` signature is non-`async`.
- [ ] lint + vet clean

## Notes

Depends on T1 (`completeDungeonRun()` must exist first). Blocks T10 (view wiring).

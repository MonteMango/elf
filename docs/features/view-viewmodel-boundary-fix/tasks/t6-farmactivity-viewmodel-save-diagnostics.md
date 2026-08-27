---
id: T6
title: "Replace try? await session.save() with session.saveInBackground() in FarmActivityViewModel"
layer: "app"
deps: []
acs: ["AC-05", "AC-07"]
files_hint: ["Packages/elf_Kit/Sources/UILayer/FarmActivity/FarmActivityViewModel.swift", "Packages/elf_Kit/Tests/elf_KitTests/UILayer/FarmActivity/FarmActivityViewModel_SaveDiagnosticsTests.swift"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T6 — Replace try? await session.save() with session.saveInBackground() in FarmActivityViewModel

## Why

`FarmActivityViewModel.swift:147,156` silently discard save errors via `try? await session.save()`, bypassing the project's already-established logged-error convention (`GameSession.saveInBackground()`) — [spec §1](../spec.md), [sad §8 Logging concept](../sad.md).

## What

Replace both `try? await session.save()` call sites with `session.saveInBackground()`.

## Definition of Done

- [ ] Unit test: both call sites now route through `saveInBackground()`.
- [ ] Unit test: a forced save failure is observable via `DebugGameLogger`.
- [ ] lint + vet clean

## Notes

Spec §8 open question: `FarmActivityViewModel.swift:146`'s `Task.isCancelled` is currently unreachable in production; the `feature/structured-task-cancellation` branch may make it reachable — this call site should be re-checked when that branch merges. Not blocking for this task.

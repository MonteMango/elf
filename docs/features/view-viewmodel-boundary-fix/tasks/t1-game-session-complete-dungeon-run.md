---
id: T1
title: "Add GameSession.completeDungeonRun() with idempotent early return"
layer: "domain"
deps: []
acs: ["AC-03", "AC-04", "AC-07"]
files_hint: ["Packages/elf_Kit/Sources/DataLayer/Sessions/GameSession.swift", "Packages/elf_Kit/Tests/elf_KitTests/DataLayer/Sessions/GameSession_DungeonRunCompletionTests.swift"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T1 — Add GameSession.completeDungeonRun() with idempotent early return

## Why

ADR-0001 hosts the shared dungeon-run-completion logic directly on `GameSession` rather than a new DI service, per the class's own architectural doc-comment ("no separate service layer underneath"). This is the single owner both the Finish path (T3) and the hero-death path (T4) will call — [ADR-0001](../adr/0001-host-dungeon-completion-on-game-session.md), [sad §4 point 2](../sad.md).

## What

Add `completeDungeonRun()` to `GameSession.swift`, wrapping the already-existing `finishDungeonRun()` + `saveInBackground()` pair. It must early-return (no reward re-payout, no save call) when there is no active `dungeonSession` — satisfying idempotency for AC-03/AC-04.

## Definition of Done

- [ ] Unit test: with an active dungeon run, `completeDungeonRun()` finishes the run and triggers `saveInBackground()`.
- [ ] Unit test: with no active dungeon run (already completed or never started), `completeDungeonRun()` is a no-op — no reward payout, no save triggered.
- [ ] lint + vet clean

## Notes

Do not introduce a new DI-injectable service (Option 2 from the ADR was explicitly rejected) — the method lives directly on `GameSession`, matching `finishDungeonRun()`/`bankDungeonRewardsOnDeath()`/`saveInBackground()`'s existing form.

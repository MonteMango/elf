---
id: T11
title: "Extract DungeonLifecycleMutator from GameSession"
layer: "domain"
deps: []
acs: ["AC-03", "AC-06"]
files_hint: [
  "Packages/elf_Kit/Sources/DataLayer/Sessions/GameSession.swift",
  "Packages/elf_Kit/Sources/DataLayer/Services/DungeonLifecycle/"
]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T11 — Extract DungeonLifecycleMutator

## Why

[ADR-0002](../adr/0002-facade-orchestrator-mutator-injection.md): the Dungeon Session Lifecycle MARK (line ~495) lives inside `GameSession`, not `DungeonSession` — confirmed by direct inspection. `startDungeonSession`/`releaseDungeonSession`/`flushRewards`/`bankDungeonRewardsOnDeath`/`finishDungeonRun`/`discardDungeonRun` are this domain-rule family.

## What

Extract all six methods' logic into `DungeonLifecycleMutator` under `Packages/elf_Kit/Sources/DataLayer/Services/DungeonLifecycle/` — the standard DI triad. Reduce each `GameSession` method to one delegating call.

## Definition of Done

- [ ] `DungeonLifecycleMutator` is a separate injected type with its own unit test
- [ ] all six `GameSession` methods reduce to one delegating call each
- [ ] existing tests pass unchanged

## Notes

Shares `GameSession.swift` with T4, T6, T7, T8, T10, T12. Feeds T12's convergence check. Not to be confused with `DungeonSession.swift`'s own lifecycle-adjacent methods (T13/T14) — this is `GameSession`'s dungeon-session bookkeeping.

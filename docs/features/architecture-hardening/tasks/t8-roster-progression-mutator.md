---
id: T8
title: "Extract RosterProgressionMutator from GameSession"
layer: "domain"
deps: []
acs: ["AC-03", "AC-06"]
files_hint: [
  "Packages/elf_Kit/Sources/DataLayer/Sessions/GameSession.swift",
  "Packages/elf_Kit/Sources/DataLayer/Services/RosterProgression/"
]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T8 — Extract RosterProgressionMutator

## Why

[ADR-0002](../adr/0002-facade-orchestrator-mutator-injection.md): `addExperience`/`addDrops` ("any elf", Roster Progression MARK, line ~232/239) and `addDropsToPlayerInventory` (Player Progression MARK, line ~165/177) are the same progression-rule family and belong in one mutator.

## What

Extract both MARK groups' logic into `RosterProgressionMutator` under `Packages/elf_Kit/Sources/DataLayer/Services/RosterProgression/` — the standard DI triad. Reduce `GameSession.addExperience`, `.addDrops`, and `.addDropsToPlayerInventory` (×2) to single delegating calls.

## Definition of Done

- [ ] `RosterProgressionMutator` is a separate injected type with its own unit test
- [ ] all four `GameSession` methods reduce to one delegating call each
- [ ] existing tests pass unchanged

## Notes

Shares `GameSession.swift` with T4, T6, T7, T10, T11, T12. Feeds T12's convergence check.

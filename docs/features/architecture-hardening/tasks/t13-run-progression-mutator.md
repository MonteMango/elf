---
id: T13
title: "Extract RunProgressionMutator from DungeonSession"
layer: "domain"
deps: []
acs: ["AC-03", "AC-06"]
files_hint: [
  "Packages/elf_Kit/Sources/DataLayer/Sessions/DungeonSession.swift",
  "Packages/elf_Kit/Sources/DataLayer/Services/RunProgression/"
]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T13 — Extract RunProgressionMutator

## Why

[ADR-0002](../adr/0002-facade-orchestrator-mutator-injection.md), [sad §6 flow 4](../sad.md): `beginRun` (line ~139), `restoreQuarter` (line ~154), `apply(_:)` (line ~167), and `moveSquadToNextRoom` (line ~263) form `DungeonSession`'s run-progression rule family.

## What

Extract these four methods' logic into `RunProgressionMutator` under `Packages/elf_Kit/Sources/DataLayer/Services/RunProgression/` — the standard DI triad. Reduce each `DungeonSession` method to one delegating call.

## Definition of Done

- [ ] `RunProgressionMutator` is a separate injected type with its own unit test
- [ ] all four `DungeonSession` methods reduce to one delegating call each
- [ ] existing tests pass unchanged

## Notes

Shares `DungeonSession.swift` with T14. Feeds T14's convergence check.

---
id: T15
title: "Extract RoundExecutionMutator from BattleFightViewModel"
layer: "domain"
deps: []
acs: ["AC-03", "AC-06"]
files_hint: [
  "Packages/elf_Kit/Sources/UILayer/BattleFight/BattleFightViewModel.swift",
  "Packages/elf_Kit/Sources/DataLayer/Services/RoundExecution/"
]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T15 — Extract RoundExecutionMutator

## Why

[ADR-0002](../adr/0002-facade-orchestrator-mutator-injection.md), [sad §6 flow 5](../sad.md): `executeFightRound` (line ~264), `executeWatchUntilEnd` (line ~285), `runRound` (line ~302), `determineBattleOutcome` (line ~396) form `BattleFightViewModel`'s round-execution rule family.

## What

Extract these four methods' logic into `RoundExecutionMutator` under `Packages/elf_Kit/Sources/DataLayer/Services/RoundExecution/` — the standard DI triad. Reduce each `BattleFightViewModel` method to one delegating call.

## Definition of Done

- [ ] `RoundExecutionMutator` is a separate injected type with its own unit test
- [ ] all four `BattleFightViewModel` methods reduce to one delegating call each
- [ ] `BattleFightViewModelTests` and other existing tests pass unchanged

## Notes

Shares `BattleFightViewModel.swift` with T16, T17. Feeds T17's convergence check.

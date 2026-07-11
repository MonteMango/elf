---
id: T16
title: "Extract DuelPairingMutator from BattleFightViewModel"
layer: "domain"
deps: []
acs: ["AC-03", "AC-06"]
files_hint: [
  "Packages/elf_Kit/Sources/UILayer/BattleFight/BattleFightViewModel.swift",
  "Packages/elf_Kit/Sources/DataLayer/Services/DuelPairing/"
]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T16 — Extract DuelPairingMutator

## Why

[ADR-0002](../adr/0002-facade-orchestrator-mutator-injection.md), [sad §6 flow 5](../sad.md): `generateNewRoundPairings` (Duel Pairs MARK, line ~405) is its own distinct domain-rule family.

## What

Extract `generateNewRoundPairings`'s logic into `DuelPairingMutator` under `Packages/elf_Kit/Sources/DataLayer/Services/DuelPairing/` — the standard DI triad. Reduce `BattleFightViewModel.generateNewRoundPairings` to one delegating call.

## Definition of Done

- [ ] `DuelPairingMutator` is a separate injected type with its own unit test
- [ ] `BattleFightViewModel.generateNewRoundPairings` is a single delegating call
- [ ] existing tests pass unchanged

## Notes

Shares `BattleFightViewModel.swift` with T15, T17. Feeds T17's convergence check.

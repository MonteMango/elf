---
id: T7
title: "Extract RewardApplicationMutator from GameSession's Battle-conclusion logic"
layer: "domain"
deps: []
acs: ["AC-03", "AC-04", "AC-06"]
files_hint: [
  "Packages/elf_Kit/Sources/DataLayer/Sessions/GameSession.swift",
  "Packages/elf_Kit/Sources/DataLayer/Services/RewardApplication/"
]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T7 — Extract RewardApplicationMutator

## Why

[spec AC-04](../spec.md) invariant #1 + [ADR-0002](../adr/0002-facade-orchestrator-mutator-injection.md): `concludeHuntBattle` (`GameSession.swift`, Battle conclusion MARK, line ~198) must keep computing the reward result against pre-mutation state before exp/inventory mutate, and this rule must move to its own injected mutator. This is [sad §6 flow 1](../sad.md).

## What

1. **Write first** a named regression test asserting the invariant: the reward result is computed against the state *before* exp/inventory mutation (fails if the order is violated).
2. Extract `concludeHuntBattle`'s reward logic into `RewardApplicationMutator` under `Packages/elf_Kit/Sources/DataLayer/Services/RewardApplication/` — the standard `{Service}+Dependency.swift` triad (protocol, `Implementation/`, `Dependencies/`).
3. Reduce `GameSession.concludeHuntBattle` to one delegating call into the mutator.

## Definition of Done

- [ ] the AC-04 invariant #1 regression test is written before the extraction and passes after it
- [ ] `RewardApplicationMutator` is a separate injected type with its own unit test (not an extension of `GameSession`)
- [ ] `GameSession.concludeHuntBattle` is a single delegating call
- [ ] existing tests pass unchanged

## Notes

Shares `GameSession.swift` with T4, T6, T8, T10, T11, T12. Feeds T12's `GameSession` convergence check.

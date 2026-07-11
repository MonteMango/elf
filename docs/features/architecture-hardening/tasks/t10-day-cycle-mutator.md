---
id: T10
title: "Extract DayCycleMutator from GameSession"
layer: "domain"
deps: []
acs: ["AC-03", "AC-06"]
files_hint: [
  "Packages/elf_Kit/Sources/DataLayer/Sessions/GameSession.swift",
  "Packages/elf_Kit/Sources/DataLayer/Services/DayCycle/"
]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T10 — Extract DayCycleMutator

## Why

[ADR-0002](../adr/0002-facade-orchestrator-mutator-injection.md): the Day Management MARK (`advanceToNextDay`, line ~85) — AP reset, buff expiry — is a distinct domain-rule family that belongs in its own injected mutator.

## What

Extract `advanceToNextDay`'s logic into `DayCycleMutator` under `Packages/elf_Kit/Sources/DataLayer/Services/DayCycle/` — the standard DI triad. Reduce `GameSession.advanceToNextDay` to one delegating call.

## Definition of Done

- [ ] `DayCycleMutator` is a separate injected type with its own unit test
- [ ] `GameSession.advanceToNextDay` is a single delegating call
- [ ] existing tests pass unchanged

## Notes

Shares `GameSession.swift` with T4, T6, T7, T8, T11, T12. Feeds T12's convergence check.

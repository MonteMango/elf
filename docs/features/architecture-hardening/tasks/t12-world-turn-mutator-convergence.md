---
id: T12
title: "Extract WorldTurnMutator and run GameSession orchestrator convergence check"
layer: "domain"
deps: ["T6", "T7", "T8", "T9", "T10", "T11"]
acs: ["AC-03", "AC-04", "AC-06"]
files_hint: [
  "Packages/elf_Kit/Sources/DataLayer/Sessions/GameSession.swift",
  "Packages/elf_Kit/Sources/DataLayer/Services/WorldTurn/"
]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T12 — Extract WorldTurnMutator + GameSession convergence check

## Why

[spec AC-04](../spec.md) invariant #2 + [ADR-0002](../adr/0002-facade-orchestrator-mutator-injection.md): `applyWorldTurn` (World Turn MARK, line ~334) must preserve its roster-reshuffle guard (each target elf's `id` still matches its expected roster slot before mutating) when extracted. This is the last `GameSession` mutator, so this task also runs the facade-wide convergence check once all of T6–T11 have landed.

## What

1. **Write first** a named regression test for the roster-reshuffle guard (fails if the party roster changes mid-`applyWorldTurn` resolution without being caught).
2. Extract `applyWorldTurn`'s logic into `WorldTurnMutator` under `Packages/elf_Kit/Sources/DataLayer/Services/WorldTurn/` — the standard DI triad. Reduce `GameSession.applyWorldTurn` to one delegating call.
3. **Convergence check**: re-read `GameSession.swift` end-to-end and confirm no inline domain-rule mutation remains outside the intentional exceptions (Equipment/Crafting/Persistence, [sad §4](../sad.md)), and that every mutator extracted in T6–T12 passes AC-06's real-delegation test (separate injected type, own unit test, facade reduced to one call — not logic relocated into more extension files).

## Definition of Done

- [ ] the AC-04 invariant #2 regression test is written before the extraction and passes after it
- [ ] `WorldTurnMutator` is a separate injected type with its own unit test
- [ ] `GameSession.applyWorldTurn` is a single delegating call
- [ ] the convergence check confirms `GameSession` has 0 remaining inline domain-rule mutation (advisory LOC target: ≤300, per [spec §7](../spec.md) — not a hard gate)
- [ ] existing tests pass unchanged

## Notes

`sad.md` §6 flagged the world-turn sequence diagram as an open question pending this exact guard's confirmed shape ([sad §11](../sad.md)) — resolve the guard's real shape against current code here, don't guess from the SAD's description alone.

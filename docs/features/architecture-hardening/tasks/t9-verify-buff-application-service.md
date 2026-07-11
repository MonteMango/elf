---
id: T9
title: "Verify BuffApplicationService already satisfies AC-06 and close any test gap"
layer: "tests"
deps: []
acs: ["AC-06"]
files_hint: [
  "Packages/elf_Kit/Sources/DataLayer/Services/BuffApplication/",
  "Packages/elf_Kit/Sources/DataLayer/Sessions/GameSession.swift",
  "Packages/elf_Kit/Sources/UILayer/BattleFight/BattleFightViewModel.swift"
]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T9 — Verify BuffApplicationService AC-06 compliance

## Why

**Correction to sad.md §5**: `sad.md` lists `BuffApplication` as a NEW mutator, but direct inspection (2026-07-10) found `BuffApplicationService` already exists with its full `{Service}+Dependency.swift` triad, and `GameSession.applyGlobalBuffToPlayer`/`applyGlobalBuff` (lines 306/315) plus `BattleFightViewModel.applyBattleBuff` (line 189) already delegate to it as one-line calls. This task verifies AC-06 rather than re-extracting already-extracted logic — see the epic's "Pre-existing-code correction" note.

## What

- Confirm `BuffApplicationService`'s own unit test covers both call paths (`applyAsGlobal` from `GameSession`, `applyAsBattle` from `BattleFightViewModel`); add the missing coverage if either is untested.
- Read `BattleFightViewModel.rescaleCurrentVitals` (line 212, private, HP/MP proportional rescaling) and record an explicit disposition: it stays inline as vitals-scaling, not the buff-application domain rule itself, so it does not need extraction under ADR-0002's Player Actions/Data Loading carve-out.
- Confirm both `GameSession` and `BattleFightViewModel` call sites are still single delegating calls (no drift since the SAD was written).

## Definition of Done

- [ ] `BuffApplicationService`'s unit test covers both `applyAsGlobal` and `applyAsBattle`
- [ ] `rescaleCurrentVitals`'s stays-inline disposition is recorded (in this task's PR description or a code comment, per [Notes])
- [ ] both call sites remain one-line delegating calls

## Notes

This finding should be flagged at `implement`/`review` since it's a real deviation from `sad.md` §5's "12 new mutator types" framing — 10 net new + this verification, not 12 new.

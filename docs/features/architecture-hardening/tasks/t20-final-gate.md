---
id: T20
title: "Final gate: build, test, lint and performance-regression check"
layer: "tests"
deps: ["T1", "T2", "T5", "T12", "T14", "T17", "T18", "T19"]
acs: ["AC-01", "AC-03"]
files_hint: ["docs/features/architecture-hardening/tasks/tracker.md"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T20 — Final gate

## Why

[spec AC-01](../spec.md) / [sad §10 QG-3](../sad.md): the whole bundle is behaviour-neutral only if the full gate passes together, not task-by-task in isolation.

## What

Run, in order:
1. `xcodebuild -scheme elf -destination 'platform=iOS Simulator,name=iPhone 17' build`
2. `xcodebuild test -scheme elf_Kit -destination 'platform=iOS Simulator,name=iPhone 17'`
3. `swiftlint --strict`
4. `battle_simulation_IntegrationTests` (already run as part of step 2) — compare its duration to T1's recorded baseline

## Definition of Done

- [ ] build: 0 errors, 0 new warnings
- [ ] tests: 100% of existing tests pass (≥420 per [sad §10 QG-3](../sad.md)'s re-verified count)
- [ ] `swiftlint --strict`: 0 violations
- [ ] `battle_simulation_IntegrationTests` duration within ±5% of the T1 baseline

## Notes

This is the epic's terminal gate — depends on every other task via its direct dependents (T12/T14/T17 already transitively cover T6–T11/T13/T15/T16/T9).

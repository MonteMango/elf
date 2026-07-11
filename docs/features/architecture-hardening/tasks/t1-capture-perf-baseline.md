---
id: T1
title: "Capture pre-refactor performance baseline"
layer: "tests"
deps: []
acs: []
files_hint: ["docs/features/architecture-hardening/tasks/tracker.md"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T1 — Capture pre-refactor performance baseline

## Why

The runtime-performance NFR ([spec §6](../spec.md)) requires comparing post-refactor timing against a pre-change baseline, but no baseline currently exists — [sad §11](../sad.md) risk row 3 flags this as a must-do-first step.

## What

Run `battle_simulation_IntegrationTests` on the current pre-refactor commit (before any other task in this epic lands) and record its duration in `tasks/tracker.md` (a short note next to T20, e.g. "baseline: Xs, captured <date>, commit <sha>").

## Definition of Done

- [ ] `battle_simulation_IntegrationTests` run, duration recorded with commit sha and date
- [ ] Recorded value is referenced by T20's ±5% check

## Notes

Must run **before** any refactor task lands — a baseline captured mid-refactor is not a valid pre-change number.

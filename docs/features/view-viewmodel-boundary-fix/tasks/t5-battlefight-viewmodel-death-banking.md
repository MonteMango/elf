---
id: T5
title: "Move death-path reward banking from BattleFightRouteView into BattleFightViewModel"
layer: "app"
deps: []
acs: ["AC-04", "AC-07"]
files_hint: ["Packages/elf_Kit/Sources/UILayer/BattleFight/BattleFightViewModel.swift", "Packages/elf_Kit/Tests/elf_KitTests/UILayer/BattleFight/BattleFightViewModel_DeathRewardBankingTests.swift"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T5 — Move death-path reward banking from BattleFightRouteView into BattleFightViewModel

## Why

`BattleFightRouteView.swift:38` is the 4th View→session bypass point — a single call site (not duplicated logic like Finish/Death-continue), so it moves behind the VM's own facade call rather than getting a shared wrapper — [spec §1 ¶3](../spec.md), [sad §4 point 2](../sad.md), [sad §6 Flow 3](../sad.md). `BattleFightViewModel` already holds `session: GameSession?` (`BattleFightViewModel.swift:29`).

## What

Move the `session.bankDungeonRewardsOnDeath()` + `saveInBackground()` calls into `BattleFightViewModel` (e.g. inside its battle-finish hook), gated on the hero being downed. Preserve the existing ordering guarantee: banking happens before `saveInBackground()`, both in the same synchronous MainActor turn (no `await` between them).

## Definition of Done

- [ ] Unit test: when the hero is downed, the VM calls `session.bankDungeonRewardsOnDeath()` then `saveInBackground()`.
- [ ] Unit test: when the hero survives, death-banking is skipped but the regular checkpoint save still happens.
- [ ] lint + vet clean

## Notes

Blocks T12 (view wiring). Independent of T1 — this path reuses the already-existing `bankDungeonRewardsOnDeath()` facade method, no new `GameSession` method needed.

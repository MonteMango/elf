---
id: T1
title: "Add per-slot validation-Task handles to HeroConfigurationState"
layer: "domain"
deps: []
acs: []
files_hint: ["Packages/elf_Kit/Sources/UILayer/Dev/BattleSetup/BattleSetupDisplayModels.swift"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T1 — Add per-slot validation-Task handles to HeroConfigurationState

## Why

Storage location and per-slot granularity are fixed by [sad §4 decision 2](../sad.md) /
[sad §5](../sad.md) and [ADR-0001](../adr/0001-scope-validation-task-handles-per-slot-and-merge-writes.md)
(Option 3): a shared per-hero handle fails AC-06 by construction, so the weapon slot and the shield
slot each need their own handle.

## What

Add two stored properties to `HeroConfigurationState`
(`Packages/elf_Kit/Sources/UILayer/Dev/BattleSetup/BattleSetupDisplayModels.swift`):
a `Task<Void, Never>?` for the `.weapons` slot and one for the `.shields` slot, initialized to `nil`.
No behavior change yet — this task only adds the storage `updateSelectedItems` (T2) will read/write.
Keep the existing stored-`Task<Void, Never>?`-handle naming convention (`GameSession.saveInFlight`
is the pattern reference, per sad §2 Conventions) but do not copy its coalescing logic — this is
pure storage, T2 owns the cancel-and-replace behavior.

## Definition of Done

- [ ] `HeroConfigurationState` exposes two independent `Task<Void, Never>?` handles (weapon-slot,
  shield-slot)
- [ ] `xcodebuild -scheme elf -destination 'platform=iOS Simulator,name=iPhone 17' build` — 0 new
  warnings
- [ ] `swiftlint --quiet` clean

## Notes

Both heroes (`playerState`, `botState`) are separate `HeroConfigurationState` instances, so no
hero-keying is needed here — AC-05's per-hero independence falls out of the existing instance split
(sad §5).

---
id: T11
title: "Wire BattleResultScreen to hold and call the new session-aware companion ViewModel"
layer: "ui"
deps: ["T4"]
acs: ["AC-03", "AC-04"]
files_hint: ["Packages/elf_iOS/Sources/Screens/BattleResultScreen/BattleResultScreen.swift"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T11 — Wire BattleResultScreen to the companion ViewModel

## Why

`BattleResultScreen.swift:109-115` performs the same View→session bypass on the hero-death path (`popToGameDay()` → `gameSession?.finishDungeonRun()` → `.saveInBackground()`) — surfaced during scope refinement, not in the original architecture review, but required for the fix's own stated goal — [spec §1](../spec.md), [spec §7 KPI baseline](../spec.md).

## What

Add a `@State` for the new companion ViewModel (from T4), created via its factory. Replace the direct `coordinator.gameSession?.finishDungeonRun()` + `.saveInBackground()` calls with the companion VM's finish method. `router.popToGameDay()` stays in the View, executed before the call, matching the DungeonScreen ordering (T10).

## Definition of Done

- [ ] `BattleResultScreen.swift` contains no direct `GameSession` mutation.
- [ ] Screen holds both the existing generic display VM and the new companion VM (precedent: `GameDayScreen` already holds two `@State` VMs).
- [ ] Build succeeds (`xcodebuild -scheme elf -destination 'platform=iOS Simulator,name=iPhone 17' build`).

## Notes

Depends on T4.

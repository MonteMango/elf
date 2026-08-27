---
id: T12
title: "Wire BattleFightRouteView to stop calling session.bankDungeonRewardsOnDeath() directly"
layer: "ui"
deps: ["T5"]
acs: ["AC-04"]
files_hint: ["Packages/elf_iOS/Sources/Navigation/RouteViews/BattleFightRouteView.swift"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T12 — Wire BattleFightRouteView off direct session mutation

## Why

`BattleFightRouteView.swift:38` calls `session.bankDungeonRewardsOnDeath()` directly — the 4th bypass point, found while refining scope beyond the original architecture review's `Screens/`-only findings — [spec §1](../spec.md), [spec §2 Goals](../spec.md) ("no View in any directory mutates session directly").

## What

Remove the direct `session.bankDungeonRewardsOnDeath()` + `.saveInBackground()` calls from `BattleFightRouteView.swift`; the banking now happens inside `BattleFightViewModel`'s battle-finish hook (T5), triggered as part of the existing `finishBattle()`-style call the View already makes.

## Definition of Done

- [ ] `BattleFightRouteView.swift` contains no direct `GameSession` mutation.
- [ ] Build succeeds (`xcodebuild -scheme elf -destination 'platform=iOS Simulator,name=iPhone 17' build`).
- [ ] Death-path reward banking still happens before the transition to `BattleResultScreen` (per sad §6 Flow 3 postcondition).

## Notes

Depends on T5.

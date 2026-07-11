---
id: T18
title: "Convert AppRoute.gameSession to a GameID payload with destination-side resolution"
layer: "ui"
deps: []
acs: ["AC-05", "AC-07"]
files_hint: [
  "Packages/elf_iOS/Sources/Navigation/AppRoute.swift",
  "Packages/elf_iOS/Sources/Navigation/RouteViews/SessionRouteView.swift",
  "Packages/elf_iOS/Sources/Screens/GameDayScreen/GameDayScreen.swift"
]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T18 — Convert AppRoute.gameSession to a GameID payload

## Why

[spec AC-05](../spec.md)/[AC-07](../spec.md), [ADR-0003](../adr/0003-approute-id-payload-with-destination-resolution.md): `.gameSession(Game, playTime:)` (line 18) carries a full domain model plus hand-written equality; the current view construction (line 127) ignores its payload entirely — a real gap this closes.

## What

- Change `AppRoute.gameSession`'s payload from `Game` to `GameID` (keep `playTime:` — [spec ¶4](../spec.md) flags it as unread but out of scope for this bundle, leave as-is).
- Remove the case's hand-written `==`/`hash(into:)` lines (38–113) — `GameID`'s synthesized `Hashable` matches the prior `Game.id`-based comparison exactly.
- At the destination, resolve `Game` from the active session by `GameID` via `SessionRouteView` (the same adapter pattern as `.hunt`/`.farm`/`.craft`/`.questList`); if the `GameID` no longer matches the active session, silently pop back to the previous screen instead of crashing ([sad §6 flow 2](../sad.md)).

## Definition of Done

- [ ] `AppRoute.gameSession` carries `GameID`, no hand-written equality remains for this case
- [ ] `GameDayScreen` is presented with the resolved `Game` when the `GameID` matches
- [ ] a `GameID` mismatch pops back silently, no crash
- [ ] push/pop/re-push de-dup behaviour is unchanged (manual navigation pass)
- [ ] existing tests pass unchanged

## Notes

Shares `AppRoute.swift` with T19 — both touch the same `==`/`hash(into:)` extension; expect these two tasks to be reviewed/committed together or in tight sequence.

---
id: T19
title: "Convert AppRoute.calendar to a zero-payload case with destination-side resolution"
layer: "ui"
deps: []
acs: ["AC-05", "AC-07"]
files_hint: [
  "Packages/elf_iOS/Sources/Navigation/AppRoute.swift",
  "Packages/elf_iOS/Sources/Navigation/RouteViews/SessionRouteView.swift"
]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T19 — Convert AppRoute.calendar to a zero-payload case

## Why

[spec AC-05](../spec.md)/[AC-07](../spec.md), [ADR-0003](../adr/0003-approute-id-payload-with-destination-resolution.md): `.calendar(calendar: [GameDay], currentDayNumber:)` (line 19) carries the whole calendar array plus hand-written equality that's semantically load-bearing (compares by array-count + day-number, not identity, per [spec ¶4](../spec.md)) — converting to zero-payload removes the equality without losing that semantics, since all current push sites always pass the session's own current calendar/day.

## What

- Change `AppRoute.calendar` to a zero-payload case (`case calendar`).
- Remove the case's hand-written `==`/`hash(into:)` lines — a payload-less case is always equal to itself, matching the prior "any two calendar pushes de-dup" behaviour in practice.
- At the destination, resolve the calendar + current day directly from the session via the same `SessionRouteView` pattern used by `.hunt`/`.farm`/`.craft`/`.questList` (currently `CalendarScreen` builds directly from the route payload at line 129 — change it to read from the session instead).

## Definition of Done

- [ ] `AppRoute.calendar` is zero-payload, no hand-written equality remains for this case
- [ ] the calendar destination screen resolves calendar + current day from the session, not the route payload
- [ ] push/pop/re-push de-dup behaviour is unchanged (manual navigation pass)
- [ ] existing tests pass unchanged

## Notes

Shares `AppRoute.swift` with T18 — both touch the same `==`/`hash(into:)` extension; expect these two tasks to be reviewed/committed together or in tight sequence.

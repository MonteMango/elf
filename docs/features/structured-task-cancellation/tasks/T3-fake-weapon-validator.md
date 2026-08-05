---
id: T3
title: "Add a controllable fake WeaponValidator test double"
layer: "tests"
deps: []
acs: []
files_hint: ["Packages/elf_Kit/Tests/elf_KitTests/Helpers/FakeWeaponValidator.swift"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T3 — Add a controllable fake WeaponValidator test double

## Why

The NFR "Race safety" (spec §6) requires the regression test to release each `validateAndResolve`
call's result in a chosen order — deterministically, not via `Task.sleep`/wall-clock timing, which
cannot guarantee ordering. No such double exists yet (only `FakeItemsRepository` is in
`Tests/elf_KitTests/Helpers/`).

## What

Add `FakeWeaponValidator` to `Packages/elf_Kit/Tests/elf_KitTests/Helpers/`, conforming to
`WeaponValidator` (`Packages/elf_Kit/Sources/DataLayer/Validators/WeaponValidator/WeaponValidator.swift`).
Give the test author control over when each call's `await` returns (e.g. per-call continuations or
an injected release-order mechanism keyed by the selected item), and what it resolves to, so a test
can start call A, then call B, then choose to resolve B before A (or vice versa) without relying on
timing. Mirror `FakeItemsRepository`'s style (`nonisolated(unsafe)` mutable state, `@unchecked
Sendable`) already used in this test helpers directory.

## Definition of Done

- [ ] `FakeWeaponValidator` conforms to `WeaponValidator`
- [ ] A test can force a specific resolution order across ≥2 concurrent `validateAndResolve` calls,
  deterministically
- [ ] `swiftlint --quiet` clean

## Notes

Pure test infrastructure — no dependency on T1/T2, can be built in parallel with them. T4 consumes
this double.

---
id: T4
title: "Regression suite for rapid re-selection, cross-slot, cross-hero and neutrality cases"
layer: "tests"
deps: ["T2", "T3"]
acs: ["AC-01", "AC-02", "AC-03", "AC-04", "AC-05", "AC-06"]
files_hint: ["Packages/elf_Kit/Tests/elf_KitTests/UILayer/Dev/BattleSetup/BattleSetupViewModelTests.swift"]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T4 — Regression suite for rapid re-selection, cross-slot, cross-hero and neutrality cases

## Why

Derives from [spec §5 AC-01 through AC-06](../spec.md) and [sad §6 flows 1-4](../sad.md) /
[sad §10 QG-1/QG-2/QG-3](../sad.md). Every AC in this feature is a concurrency-ordering guarantee
that a wall-clock test cannot prove — the suite must use T3's controllable fake to force each
ordering.

## What

New test file `Packages/elf_Kit/Tests/elf_KitTests/UILayer/Dev/BattleSetup/BattleSetupViewModelTests.swift`,
using `FakeWeaponValidator` (T3), covering:
- **Same-slot rapid re-selection** (AC-01, AC-03, AC-04): select weapon A, then weapon B before A's
  validation resolves; release A's result *after* B's — assert the hero's `selectedItems` reflects
  only B, and that at no point does a stale A write occur.
- **Cross-slot rapid re-selection** (AC-06): select weapon A, then shield B before A resolves;
  release in either order — assert both the final weapon and final shield choices are present in
  `selectedItems` (sad §6 flow 2).
- **Cross-hero independence** (AC-05): concurrent in-flight validations for `playerState` and
  `botState` — assert selecting for one hero never affects the other's pending Task or its
  `selectedItems` (sad §6 flow 3).
- **Neutrality / rejection-auto-resolution** (AC-02): a single, non-rapid selection that the
  validator rejects or auto-resolves — assert the outcome is applied unchanged from pre-fix behavior
  (sad §6 flow 4).
- Run the full existing `elf_Kit` suite alongside to confirm no regression (spec §6 NFR "Behavior
  neutrality").

## Definition of Done

- [ ] All new tests above pass
- [ ] `xcodebuild test -scheme elf_Kit -destination 'platform=iOS Simulator,name=iPhone 17'` — 100%
  pass, no regressions
- [ ] `swiftlint --quiet` clean

## Notes

Depends on T2 (the production fix) and T3 (the fake validator). This is the task that closes out
the feature's NFR table (spec §6) and sad §10 quality gates QG-1/QG-2/QG-3.

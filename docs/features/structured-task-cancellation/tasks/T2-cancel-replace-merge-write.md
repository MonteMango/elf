---
id: T2
title: "Cancel-and-replace + merge-on-write in updateSelectedItems"
layer: "domain"
deps: ["T1"]
acs: ["AC-01", "AC-02", "AC-03", "AC-04", "AC-06"]
files_hint: ["Packages/elf_Kit/Sources/UILayer/Dev/BattleSetup/BattleSetupViewModel.swift"]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T2 — Cancel-and-replace + merge-on-write in updateSelectedItems

## Why

Derives from [spec §5 AC-01/AC-02/AC-03/AC-04/AC-06](../spec.md), [sad §6 flows 1/2/4](../sad.md),
and [ADR-0001](../adr/0001-scope-validation-task-handles-per-slot-and-merge-writes.md). The current
`updateSelectedItems` (`BattleSetupViewModel.swift:170-191`) starts an ad hoc, unstored `Task {}` per
validated selection and writes back the validator's entire returned dict — both the race (AC-01/04)
and the lost-update on write (AC-06) trace to this one method.

## What

In `updateSelectedItems` (`Packages/elf_Kit/Sources/UILayer/Dev/BattleSetup/BattleSetupViewModel.swift`),
for the `requiresValidation` branch:
- Before starting a new `Task`, cancel the slot's existing handle (T1) for this hero and store the
  new `Task` on that same handle (cancel-and-replace, AC-04).
- At the write point (after `await`), only apply the write if the completing `Task` is still the
  slot's current handle — a superseded/cancelled `Task` must not write (AC-03).
- Change the write itself from a full-dict assignment to merge-on-write: diff the validator's
  returned dict against the `currentItems` snapshot it was given to find the actually-changed key(s),
  then apply only those key(s) onto `selectedItems` **as it is at write time** — not onto the stale
  pre-`await` snapshot (ADR-0001 Option 3; closes the AC-06 lost-update).
- Leave the non-validated branch (`else`) and `requiresValidation`/`getCurrentItemId` untouched — no
  behavior change there.

## Definition of Done

- [ ] A single, non-rapid weapon/shield selection resolves exactly as before (AC-02; regression test
  in T4)
- [ ] A rapid same-slot re-selection: only the final selection's outcome is ever applied (AC-01);
  the superseded Task's result, if it completes anyway, is discarded (AC-03); at most one Task per
  slot is ever active (AC-04)
- [ ] A rapid cross-slot re-selection (weapon then shield or vice versa) preserves both final choices
  (AC-06)
- [ ] `swiftlint --quiet` clean

## Notes

Depends on T1's two handles existing on `HeroConfigurationState`. Verified by T4's regression suite
(this task alone is not testable in isolation without T3's fake validator — implement together with
T3/T4 in the same PR per the feature's single-PR/XS scope, spec §6).

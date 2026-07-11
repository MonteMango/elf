---
id: T17
title: "Split BattleFightViewModel+Display and run BattleFightViewModel orchestrator convergence check"
layer: "ui"
deps: ["T9", "T15", "T16"]
acs: ["AC-06"]
files_hint: [
  "Packages/elf_Kit/Sources/UILayer/BattleFight/BattleFightViewModel.swift",
  "Packages/elf_Kit/Sources/UILayer/BattleFight/BattleFightViewModel+Display.swift"
]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T17 — BattleFightViewModel+Display split + convergence check

## Why

[sad §4 decision 2](../sad.md): pure display/formatting logic belongs in a `+Display.swift` extension (the proven `InventoryViewModel+DisplayItems.swift` precedent) — extension files are fine for derivation, never for domain mutation ([spec AC-06](../spec.md)). This is the last `BattleFightViewModel` task, so it also runs the facade-wide convergence check.

## What

1. Move `BattleFightViewModel`'s pure display/formatting derivations into a new `BattleFightViewModel+Display.swift` extension file, following the `InventoryViewModel+DisplayItems.swift` pattern.
2. **Convergence check**: re-read `BattleFightViewModel.swift` end-to-end and confirm no inline domain-rule mutation remains outside the intentional exceptions (Player Actions/Data Loading, [sad §4](../sad.md)), and that T9's `BuffApplicationService` verification plus T15/T16's mutators all pass AC-06's real-delegation test.

## Definition of Done

- [ ] `BattleFightViewModel+Display.swift` exists and holds only derivation/formatting, no mutation
- [ ] the convergence check confirms `BattleFightViewModel` has 0 remaining inline domain-rule mutation (advisory LOC target: ≤300, per [spec §7](../spec.md) — not a hard gate)
- [ ] `BattleFightViewModelTests` and other existing tests pass unchanged

## Notes

Depends on T9 (buff verification), T15, T16 (both mutators) — all touch `BattleFightViewModel.swift`.

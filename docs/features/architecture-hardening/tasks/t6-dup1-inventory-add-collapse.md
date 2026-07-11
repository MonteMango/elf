---
id: T6
title: "DUP-1: collapse the three inventory-add methods into one core path"
layer: "domain"
deps: []
acs: ["AC-09"]
files_hint: ["Packages/elf_Kit/Sources/DataLayer/Sessions/GameSession.swift"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T6 — DUP-1: collapse the three inventory-add methods

## Why

[spec AC-09](../spec.md): `addFishToInventory`/`addHerbsToInventory`/`addOresToInventory` (`GameSession.swift` lines 261/269/277) are three near-identical methods. **Correction to sad.md §5**: direct inspection found all three already delegate to the existing injected `InventoryService.addMaterials(...)` — the remaining duplication is the three `map` transforms, not three independent domain-logic copies, so this is a map-collapse inside `GameSession`, not a new service triad.

## What

Collapse the three `map` + `addMaterials(...)` transforms into one core add path (e.g. a single generic `add(_ refs: [MaterialRef])` or an enum-driven mapper) inside `GameSession`, still calling the existing `inventoryService`. Keep all three public methods as thin typed shims with their exact original signatures at every call site.

## Definition of Done

- [ ] one core add path exists; the three public methods are shims over it with unchanged signatures
- [ ] existing tests pass unchanged
- [ ] lint clean

## Notes

Shares `GameSession.swift` with T4, T7, T8, T10, T11, T12 — expect this file to be touched by several tasks in this epic; each should apply cleanly against the others' changes since they touch distinct MARK groups.

---
id: T2
title: "Fix the two AC-08 documentation issues"
layer: "docs"
deps: []
acs: ["AC-08"]
files_hint: ["Packages/elf_Kit/Sources/DataLayer/Sessions/GameStore.swift", "CLAUDE.md"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T2 — Fix the two AC-08 documentation issues

## Why

[spec AC-08](../spec.md) names exactly two already-identified documentation issues — a stale doc comment and a platform-declaration mismatch. Scope is these two items only, not a repo-wide audit ([spec §3](../spec.md)).

## What

- Remove/correct the stale comment referencing `DefaultGameService` at `Packages/elf_Kit/Sources/DataLayer/Sessions/GameStore.swift:21`.
- Update `CLAUDE.md`'s platform lines (`iOS 17+` at line 4 and line 50) to `iOS 18+`, matching the actual `.iOS(.v18)` declared in all three `Package.swift` files ([sad §2](../sad.md) Technical constraints).

## Definition of Done

- [ ] `GameStore.swift:21`'s stale comment no longer references the wrong type
- [ ] `CLAUDE.md` platform lines read iOS 18+, matching `Package.swift`
- [ ] lint clean

## Notes

Purely mechanical — no behaviour change, no test impact.

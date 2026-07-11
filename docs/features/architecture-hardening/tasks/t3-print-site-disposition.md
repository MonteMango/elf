---
id: T3
title: "Resolve persistence-layer and AppCoordinator print-site disposition"
layer: "wiring"
deps: []
acs: ["AC-02"]
files_hint: [
  "Packages/elf_Kit/Sources/DataLayer/Persistence/Implementation/FileGameSaveStorage.swift",
  "Packages/elf_Kit/Sources/DataLayer/Persistence/Model/DungeonRunRewardsSaveData.swift",
  "Packages/elf_iOS/Sources/Coordinator/AppCoordinator.swift",
  ".swiftlint.yml"
]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T3 — Resolve persistence-layer and AppCoordinator print-site disposition

## Why

[sad §11](../sad.md) leaves two persistence-layer print sites and one Coordinator print site with no pre-approved allow-list category, explicitly deferring the per-site decision to `tasks`.

## What

- **`FileGameSaveStorage.swift`** — the private `debugLog` helper (line 13, wraps `print` at line 15) is the actual raw-print site (its ~35 call sites call `debugLog`, not `print`, so only this one line needs a disposition). **Decision: extend the SwiftLint allow-list** to cover this file — a persistence-layer diagnostic path with no straightforward DI access at its call depth, following the same rationale as the other allow-listed categories ([sad §8](../sad.md)).
- **`DungeonRunRewardsSaveData.swift`** — 2 raw `print(` sites (orphaned weapon/armor reference warnings, lines 57 and 66). **Decision: extend the allow-list** for the same reason (a `Codable`-adjacent save-data type, no logger DI reachable there).
- **`AppCoordinator.swift:101`** — a reachable logger dependency exists here. **Decision: in scope** — route this print through the logger too, even though AC-02's literal wording is "ViewModel or service" and a Coordinator is neither; cheap consistency win, no reason to leave it inconsistent.
- Add the two allow-listed paths to the SwiftLint config groundwork (the rule itself is wired in T5; this task only settles which paths belong on the list and fixes the one in-scope site).

## Definition of Done

- [ ] `FileGameSaveStorage.swift` and `DungeonRunRewardsSaveData.swift` paths recorded as allow-list entries (consumed by T5)
- [ ] `AppCoordinator.swift:101` routed through its existing logger dependency
- [ ] existing tests pass unchanged

## Notes

This task's decisions are flagged for confirmation at `implement`/`review` — [sad §11](../sad.md) explicitly left them open rather than pre-deciding.

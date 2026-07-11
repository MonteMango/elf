---
id: T14
title: "Extract RoomBattleRewardMutator and run DungeonSession orchestrator convergence check"
layer: "domain"
deps: ["T13"]
acs: ["AC-03", "AC-06"]
files_hint: [
  "Packages/elf_Kit/Sources/DataLayer/Sessions/DungeonSession.swift",
  "Packages/elf_Kit/Sources/DataLayer/Services/RoomBattleReward/"
]
owner: "Vitalii Lytvynov"
estimate: "M"
status: "todo"
---

# T14 — Extract RoomBattleRewardMutator + DungeonSession convergence check

## Why

[ADR-0002](../adr/0002-facade-orchestrator-mutator-injection.md), [sad §6 flow 4](../sad.md): `concludeRoomBattle` (line ~285), `applyBattleOutcome` (line ~346), `clearPendingRewards` (line ~362) form `DungeonSession`'s room-battle-reward rule family — the second and last of `DungeonSession`'s two mutators, so this task also runs the facade-wide convergence check.

## What

1. Extract these three methods' logic into `RoomBattleRewardMutator` under `Packages/elf_Kit/Sources/DataLayer/Services/RoomBattleReward/` — the standard DI triad. Reduce each `DungeonSession` method to one delegating call.
2. **Convergence check**: re-read `DungeonSession.swift` end-to-end and confirm no inline domain-rule mutation remains outside the intentional exception (Persistence, [sad §4](../sad.md)), and that both T13/T14's mutators pass AC-06's real-delegation test.

## Definition of Done

- [ ] `RoomBattleRewardMutator` is a separate injected type with its own unit test
- [ ] all three `DungeonSession` methods reduce to one delegating call each
- [ ] the convergence check confirms `DungeonSession` has 0 remaining inline domain-rule mutation (advisory LOC target: ≤300, per [spec §7](../spec.md) — not a hard gate)
- [ ] existing tests pass unchanged

## Notes

Depends on T13 (shares `DungeonSession.swift`).

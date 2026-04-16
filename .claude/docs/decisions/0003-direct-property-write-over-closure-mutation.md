# 0003 — Direct `player.equipped` writes replace `modifyEquipment` closures

- **Status:** accepted
- **Date:** 2026-04-16

## Context

`GameStateService` exposed two closure-based mutation helpers:

```swift
func modifyEquipment(_ transform: (inout EquippedItems) -> Void)
func modifyInventory(_ transform: (inout ElfInventory) -> Void)
```

Rationale at the time: "atomic scoped mutation — fires observation invalidation only for the
affected property". In practice these were used from:

- `modifyInventory` — one call site (`CraftViewModel.craft()`) — addressed by [0002](0002-craft-transaction-on-gameservice.md).
- `modifyEquipment` — ten call sites, **all inside `DefaultEquipmentService`**. The service
  already exposes explicit domain operations (`equipWeapon`, `unequipShield`, `equipArmor`,
  etc.). The closure was purely plumbing between the service and the underlying store.

Problems with the closure shape:
- Looks like an escape hatch — any caller can mutate any equipped field, bypassing domain logic
- Harder to read than explicit property assignments
- Adds no safety vs a direct property write (the `@Observable` invalidation scope is identical
  either way — see [threading-model.md](../threading-model.md))

## Decision

Delete both protocol methods. Rewrite all ten `modifyEquipment` call sites in
`DefaultEquipmentService` to read `gameService.player.equipped` into a local `var`, compute
the new state, and write back. Same observation semantics, explicit intent, zero new API.

```swift
// Before
gameService.modifyEquipment { equipped in
    equipped.shirt = robe
}

// After
var equipped = gameService.player.equipped
equipped.shirt = robe
gameService.player.equipped = equipped
```

## Alternatives considered

- **Keep `modifyEquipment`, narrow it to internal** — rejected: still a closure escape hatch,
  just hidden. Doesn't solve the "API looks like anything-goes" concern.
- **Add a write-only `setEquipped(_:)` to the protocol** — rejected: `player.equipped` is
  already `public var` on `PlayerStore`. An extra protocol wrapper is redundant indirection.
- **Merge equipment logic into `DefaultGameService`, delete `DefaultEquipmentService`** —
  rejected: bloats GameService with slot-determination logic (armor routing, jewelry
  priority filling). `DefaultEquipmentService` is a well-factored domain service; removing
  it would move logic in the wrong direction.

## Consequences

**Easier:**
- `DefaultEquipmentService` methods read top-to-bottom: read state → compute → write.
- `GameStateService` protocol shrinks by 2 methods.
- "Who can mutate equipment?" has a clear answer: `DefaultEquipmentService` is the entry
  point; everyone else calls its explicit methods.

**Harder:**
- Minor: services outside of `DefaultEquipmentService` that want to mutate equipment would
  now write `player.equipped = ...` directly. Currently none do. If a need arises, prefer
  adding a method to `DefaultEquipmentService` rather than spreading direct writes.

**Watch for:**
- New code writing `player.equipped = ...` from a ViewModel or unrelated service — that's
  the smell we're avoiding. Add a new operation to `DefaultEquipmentService` instead.
- `PlayerStore.equipped` is a `public var`. If the need arises to tighten it (e.g., make
  the setter `internal(set)` and route everything through a narrow mutation protocol),
  this ADR should be superseded.

## Related

- [threading-model.md](../threading-model.md) — observation rules
- [0001](0001-mainactor-observable-for-game-state.md) — the `@Observable` migration that made this possible
- [0002](0002-craft-transaction-on-gameservice.md) — sibling decision removing `modifyInventory`

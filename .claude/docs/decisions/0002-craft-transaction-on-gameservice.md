# 0002 — `craftItem` lives on `DefaultGameService`, not `CraftService`

- **Status:** accepted
- **Date:** 2026-04-16

## Context

The craft transaction (validate materials → deduct → add crafted item) previously lived
inside `CraftViewModel.craft()`, wrapped in the `modifyInventory` closure escape hatch on
`GameStateService`:

```swift
gameService.modifyInventory { [craftService, inventoryService] inventory in
    guard craftService.canCraft(recipe: recipe, inventory: inventory) else { return }
    inventory = craftService.deductMaterials(recipe: recipe, from: inventory)
    inventory = inventoryService.addCraftedItem(item, to: inventory)
}
```

That closure is domain logic in the ViewModel — a real smell (ViewModels shouldn't orchestrate
game state transactions), plus invariants aren't enforceable at the mutation boundary. See
parent refactor.

The question: where should the transaction *live*?

## Decision

Add `func craftItem(recipe: Recipe, item: Item) -> Bool` to `GameStateService` protocol and
implement it on `DefaultGameService`. The method reads `player.inventory`, runs
`craftService.canCraft` + `craftService.deductMaterials` + `inventoryService.addCraftedItem`
internally, and writes `player.inventory` atomically. `CraftService` stays pure and
`Sendable` — only queries (`canCraft`, `getMissingIngredients`, `deductMaterials`).
`CraftViewModel.craft()` becomes a one-liner: `gameService.craftItem(recipe: recipe, item: item)`.

## Alternatives considered

- **Make `CraftService` `@MainActor`, hold `GameStateService` as dep, expose `craftItem`
  there** — rejected: loses `Sendable` on pure query methods (`canCraft`, etc.), which
  should remain callable from any context (UI preview, future background simulations).
  Inconsistent with sibling `InventoryService` (stays `Sendable`).
- **Introduce a new `@MainActor CraftExecutor` service** — rejected: one-method service is
  over-engineering for a solo codebase. Extra DI wiring for no clear win.
- **Keep `CraftService` pure, orchestrate transaction from `CraftViewModel`** — rejected:
  preserves the exact domain leak we're fixing.

## Consequences

**Easier:**
- Craft behavior is one call from any ViewModel. Testable directly on `DefaultGameService`.
- `CraftService` remains pure — useful for future UI previews, balance sims, or parallel
  recipe-feasibility checks.
- Consistent with existing precedent on `GameStateService`: `addDropsToPlayerInventory`,
  `addFishToInventory`, etc. are the same shape (state-transition methods).

**Harder:**
- `DefaultGameService` grows by one method (and one `CraftService` dependency).
- `GameStateService` protocol grows.

**Watch for:**
- If several more similar transactions accrue (`enchant`, `disassemble`, `trade`,
  `sacrifice` ...), reconsider: at some point a dedicated `InventoryTransactionService` or
  actor becomes justified. Threshold is roughly "the `// MARK: - Inventory Operations`
  section exceeds ~150 lines" or "methods start sharing non-trivial logic".
- Error reporting: `craftItem` returns `Bool` today (sufficient because `canCraft` is
  available upstream for UI guards). Revisit to `throws CraftError` when the UI needs
  richer feedback ("missing 3× Iron Ore, 2× Leather").

## Related

- [threading-model.md](../threading-model.md) — observable write semantics
- [0003](0003-direct-property-write-over-closure-mutation.md) — sibling decision removing the other closure escape hatch

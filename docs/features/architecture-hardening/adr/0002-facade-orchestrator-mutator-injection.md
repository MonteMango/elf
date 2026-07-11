---
status: Accepted
owner: "Vitalii Lytvynov"
reviewers: []
updated_at: "2026-07-09"
feature_size: "L"
ticket: "architecture-hardening"
---

# 0002 — Reshape session facades and the largest ViewModel into orchestrators over DI-injected, domain-rule-family mutators

- **Status:** Accepted
- **Date:** 2026-07-09
- **Deciders:** Vitalii Lytvynov (Architect / Tech Lead / sole developer)

## Context

`GameSession` (564 LOC — re-verified 2026-07-09, up from 251 after a single dungeon-rewards feature), `DungeonSession` (365 LOC), and `BattleFightViewModel` (422 LOC) each implement domain-mutation logic directly inline rather than delegating it, by design — `GameSession`'s own doc comment says "no separate service layer beneath it; mutation logic lives directly in this type." A grounded scan of the current code (2026-07-09) confirms the shape: `GameSession` has 10 `// MARK:` groups (Day Management, Player Progression, Battle conclusion, Roster Progression, Inventory-add [the DUP-1 family], Buffs, World Turn, Crafting, Equipment, Persistence, Dungeon Session Lifecycle); `DungeonSession` has 3 (Run mutations, Persistence, Battle outcome); `BattleFightViewModel` has 4 mutation groups (Buffs, Player Actions, Round Execution, Duel Pairs) plus a separate pure view-state/display block. Two named invariants (spec AC-04) live inside this inline logic: the reward-application "compute against current values before mutation" ordering, and the world-turn roster-reshuffle guard. `architecture-hardening` must fix the *mechanism* by which these three types stop growing without bound.

## Decision drivers

- US-01 "keep the largest types small" + US-05 "a facade that orchestrates, not implements" (spec §4).
- AC-06's checkable rule: delegation counts as real only if (a) the rule lives in a separate injected type, not an extension of the original type, and (b) that type has its own unit test independent of the facade — the same logic moved into more extension files of the same type does **not** satisfy this AC regardless of resulting line count.
- AC-04: the two named invariants must each get a dedicated regression test, written *before* their mutator is extracted.
- The project's own established DI discipline (`dependency-injection.md`, memory `feedback_di_for_helpers`): Builders/Validators/Calculators/Resolvers already go through `@Dependency`, never constructed directly — this decision extends that discipline to session mutators rather than inventing a new pattern.
- Behaviour-neutrality quality goal — whatever mechanism is chosen must be provably a pure move, not a rewrite.

## Considered options

1. **DI-injected mutators grouped by domain-rule family** — each family (e.g. reward-application, inventory-add, world-turn, buffs) becomes its own protocol + `liveValue` type registered via `@Dependency`, following the project's existing `{Service}+Dependency.swift` triad; the facade snapshots each mutator in `init` and reduces each method to one delegating call. Pure display/formatting logic (the `BattleFightViewModel` view-state block) stays as a `+Display.swift` extension, matching the already-established `InventoryViewModel+DisplayItems.swift` precedent — extensions are fine for derivation, not for domain mutation.
2. **Extension-files-only split** — move each MARK group into a `GameSession+Progression.swift`-style extension of the same type, no new injected types, no independent unit tests.
3. **A new shared service layer beneath all three types** — introduce a generic `SessionMutationService` (or similar) that all three facades funnel through, unifying reward-application/buff/inventory logic across `GameSession`/`DungeonSession`/`BattleFightViewModel` into one shared component.

## Decision outcome

**Chosen:** Option 1. It is the only option that satisfies AC-06's literal, checkable rule (separate injected type + independent unit test + a facade method reduced to one delegating call) — Option 2 is explicitly disqualified by AC-06's own wording ("the same type's logic relocated into more extension files... does not satisfy this AC regardless of the resulting line count"). Option 3 was rejected because `GameSession`, `DungeonSession`, and `BattleFightViewModel` have almost no shared domain-rule vocabulary (progression vs. dungeon-run lifecycle vs. battle-round execution) — a shared service would either stay empty or accrete unrelated logic, recreating a smaller god-object one level down. Option 1 also directly reuses a pattern the codebase already trusts: the `{Service}+Dependency.swift` DI triad and the `+Display.swift` extension-for-pure-derivation precedent (`InventoryViewModel+DisplayItems.swift`), so nothing new is invented.

## Consequences

**Positive**
- Each domain-rule family becomes independently unit-testable via `withDependencies { }`, closing part of finding TEST-1 (23 ViewModels, 1 test file) opportunistically as a side effect.
- The two AC-04 invariants (reward-application ordering, world-turn roster-reshuffle guard) each get an isolated, named regression test tied to one small type instead of being buried inside a 500+ LOC facade.
- Matches the project's own DI conventions exactly — no new pattern for future contributors (including future-you) to learn.

**Negative**
- More files and more DI registrations than a pure extension split — each family adds a protocol + `Implementation/` + `+Dependency.swift` trio, which is real ceremony for what were previously a handful of private/internal methods.
- The facade's `init` grows a snapshot line per injected mutator (mirrors the existing `@Dependency` snapshot-in-init pattern already used for services, so the growth is uniform with precedent, not novel).

**Neutral**
- `Crafting` (already delegates to `CraftService`) and `Persistence`/save-lifecycle groups are **not** forced into this pattern — they either already delegate or are infrastructure/session-lifecycle concerns, not domain-mutation rules; §5 names which MARK groups become mutators and which stay in the facade.

## Links

- Spec: [[../spec.md]] §4 US-01, US-05, AC-04, AC-06
- SAD: [[../sad.md]] §4, §5
- Related ADR: [[0001-surgical-refactor-within-existing-modules]] (scopes this work to the existing modules, no new package)

# Changelog — structured-task-cancellation

## structured-task-cancellation — Dev Battle Setup no longer races weapon/shield validation Tasks

**What:** On the dev-only Battle Setup screen, rapidly re-selecting a hero's weapon or shield now
always ends up reflecting the *last* selection made — never a stale validation result that happens
to resolve out of order. Selecting a weapon and a shield back-to-back for the same hero preserves
both outcomes instead of one silently reverting the other, and the player's and bot's validation
lifecycles stay fully independent of each other.

**Why:** `BattleSetupViewModel.updateSelectedItems` used to spin up an ad hoc, unstored, uncancelled
`Task {}` for every weapon/shield compatibility check. Selecting the same slot twice in quick
succession raced two `Task`s against each other with no ordering guarantee, so whichever `await`
happened to finish last won — even if it was the *older* selection. This was finding #1 (🔴 High) in
`nextArch/possiblePlans.md`'s Фаза 1 debt sweep. See [spec](../structured-task-cancellation/spec.md)
§1 for the full problem statement and
[ADR-0001](../structured-task-cancellation/adr/0001-scope-validation-task-handles-per-slot-and-merge-writes.md)
for the chosen fix shape (per-slot `Task<Void, Never>?` handles, cancel-and-replace, merge onto live
state rather than overwrite from a pre-tap snapshot).

**How to use:** No new UI or API — the fix is purely internal to `BattleSetupViewModel`. Equip a
weapon or shield from the dev Battle Setup screen as before; rapid re-selection and cross-slot
selection now behave correctly with no visible change to the single-selection path.

**Operational notes:**
- Migration: none — no persisted state touched.
- Feature flag / config: none.
- Rollback: revert the commit range; no data migration to unwind.

**Acceptance criteria delivered:** AC-01 (last selection wins under rapid re-selection), AC-02
(a genuinely rejected/auto-resolved selection is still applied in full, including the clear-by-omission
merge fix and — per the 2026-08-26 re-review — a live re-check when a concurrent cross-slot edit made
the original decision's picture of the other slot stale), AC-03 (a superseded, cancelled Task's stale
result is barred from writing state), AC-04 (no more than the invariant's allowed concurrent validation
Tasks per hero — see the open AC-04 wording note in spec.md §8), AC-05 (player/bot Task lifecycles are
fully independent), AC-06 (cross-slot rapid selection preserves both outcomes, including when the two
slots' outcomes genuinely conflict with each other — see `_review/review-2026-08-26.md`).

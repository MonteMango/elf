<!-- Format: MADR (Markdown Any Decision Record). -->
<!-- Spawned by `design` when a decision crosses the blast-radius gate (references/blast-radius.md). -->

---
status: Accepted
owner: "Vitalii Lytvynov"
reviewers: []
updated_at: "2026-08-04"
feature_size: "XS"
ticket: "nextArch/possiblePlans.md — finding #1 (Group A)"
---

# 0001 — Scope validation-task handles per item slot and merge writes onto live state

- **Status:** Accepted
- **Date:** 2026-08-04
- **Deciders:** Vitalii Lytvynov (Architect), Swift-concurrency consultant (independent confirmation)

## Context

`BattleSetupViewModel.updateSelectedItems` starts an ad hoc, unstored `Task { }` for every weapon/shield
selection that needs compatibility validation. Two concurrent selections for the same hero race each
other, and whichever `await` resolves last wins — regardless of which selection the Developer actually
made last. The fix must store a `Task<Void, Never>?` handle and cancel-and-replace it, but the exact
handle *granularity* within a hero (shared across the weapon+shield slots, or one per slot) and the
*write strategy* back into `HeroConfigurationState.selectedItems` are not fixed by the spec — it
explicitly defers both to this design pass, only constraining the outcome: AC-06 (a rapid cross-slot
selection — weapon then shield, or vice versa, before either resolves — must preserve **both** final
choices).

## Decision drivers

- AC-04 — at most one weapon/shield-validation `Task` is active per hero at a time; the invariant must
  hold observably, even under rapid repeated selections (spec §5 AC-04).
- AC-05 — the player's and the bot's validation-`Task` lifecycles must be fully independent; selecting
  for one hero must never disturb the other hero's in-flight validation (spec §5 AC-05).
- AC-06 — a rapid cross-slot selection (weapon then shield, or vice versa) must never let one slot's
  already-made, not-yet-applied selection silently revert to its prior value (spec §5 AC-06).
- NFR "Race safety" — 0 out-of-order writes under a **deterministic** regression test using an
  injected/controllable fake `weaponValidator` that releases its result in a chosen order, not
  wall-clock timing (spec §6).

## Considered options

1. **Shared handle per hero + full-dict overwrite on write** — one `Task<Void, Never>?` per hero
   covering both the weapons and shields slots (mirrors `GameSession.saveInFlight`'s single-handle
   shape); on write, assign the validator's entire returned dict to `selectedItems`.
2. **Per-slot handles + full-dict overwrite on write** — a separate handle for each of the weapons and
   shields slots (fixes the spurious cross-slot cancellation of Option 1), but still assigns the
   validator's entire returned dict to `selectedItems` on write.
3. **Per-slot handles + merge-only-changed-keys onto live state on write** — a separate handle per slot,
   and on write, only the key(s) the validator's own call actually changed (relative to the snapshot it
   was given) are applied onto `selectedItems` **as it is at write time**, not onto the stale pre-`await`
   snapshot.

## Decision outcome

**Chosen:** Option 3. A shared per-hero handle (Option 1) fails AC-06 by construction: selecting the
shield while the weapon's validation is still in flight would cancel the weapon's `Task` even though
the Developer never touched the weapon slot — a spurious cancellation, not a superseded one — and the
weapon's own selection would never be applied. Per-slot handles alone (Option 2) fix that spurious
cancellation but leave a genuine lost-update race: a slot's `Task` captures its `currentItems` snapshot
when it *starts*, not when it resolves; if the other slot's `Task` resolves and writes first, a later-
resolving `Task` for the first slot still holds the stale pre-selection value for the other slot in its
own snapshot, and a full-dict overwrite silently reverts that other slot's just-applied selection back
to its prior value — exactly the AC-06 violation, and reachable in the plain, non-conflicting case (no
two-handed/off-hand conflict required), not only as an edge case. Only Option 3's merge-onto-live-state
write closes that gap.

## Consequences

**Positive**
- Satisfies AC-04/AC-05/AC-06 by construction, not by accident of test timing.
- `HeroConfigurationState` already owns `selectedItems`; per-slot handles live on the same instance, so
  AC-05's per-hero independence falls out for free (player and bot are already separate
  `HeroConfigurationState` instances) without a new dictionary/registry.
- Matches the NFR's deterministic-fake-validator test: the write is safe regardless of which slot's
  `Task` happens to resolve first.

**Negative**
- A few more lines per validation call site than a naive full-dict assignment: the write must diff the
  validator's input snapshot against its output to find the changed key(s), then apply only those onto
  the live `selectedItems`.

**Neutral**
- Does not re-validate a slot's outcome against the *very latest* state of the other slot — a genuine
  two-handed/off-hand conflict decided against a stale snapshot of the other slot can still, in a
  narrow residual case (a real conflict landing during a concurrent cross-slot edit), apply an
  auto-clear that doesn't reflect the other slot's latest pick. Re-validating live would need a re-run
  loop, which is over-engineering for a dev-only testing screen; accepted as debt (§11), not solved by
  this fix.

**Update — 2026-08-26:** superseded. The 2026-08-26 re-review found this residual was not the mild
case described above — it could silently drop an already-applied, valid selection, or leave a
two-handed weapon and a shield equipped simultaneously (the exact combination Option 3 exists to
prevent). `updateSelectedItems` was changed to detect a live/snapshot divergence at write time and
re-validate once against the live state before merging (a single re-run, not a loop — the residual
this leaves is the same order of magnitude as the original single-`await` race this ADR already
accepts). See `_review/review-2026-08-26.md` and `sad.md` §11.

## Links

- Spec: [[../spec.md]]
- SAD: [[../sad.md]] §5
- Related ADR: none

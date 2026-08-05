## Summary

Fixes a real state-race in the dev-only Battle Setup screen: rapid weapon/shield re-selection could
apply the *older* validation result if its `Task` happened to resolve last. Stores a per-slot
`Task<Void, Never>?` handle per hero, cancels-and-replaces on a new selection, and merges the
validated result onto live state (not a full pre-tap-snapshot overwrite) so a concurrent selection
in the other slot is never reverted. See `docs/features/structured-task-cancellation/spec.md` for
the full problem statement.

## Acceptance criteria

- AC-01 — rapid re-selection of the same slot: only the most-recent selection's outcome is ever applied ✓
- AC-02 — a genuinely rejected/auto-resolved selection is still applied in full (including the
  clear-by-omission merge fix for `ElfWeaponValidator`'s `dict[slot] = nil` clear shape) ✓
- AC-03 — a superseded, cancelled Task's stale result is denied write access to the hero's equipped state ✓
- AC-04 — the previous Task for a hero's slot is cancelled before a new one starts (see spec.md §8 for
  an open wording note: the literal "per hero" phrasing vs. the shipped "per slot" design) ✓
- AC-05 — player and bot Task lifecycles are fully independent ✓
- AC-06 — cross-slot rapid selection (weapon then shield, or vice versa) preserves both outcomes ✓

## Design

- Spec: `docs/features/structured-task-cancellation/spec.md`
- Architecture: `docs/features/structured-task-cancellation/sad.md`
- Decisions: `docs/features/structured-task-cancellation/adr/0001-scope-validation-task-handles-per-slot-and-merge-writes.md`
- Data model / API: none — no persisted state or external contract touched

## Tasks (SDD-Task trailers)

- `114b292` — T1: per-slot validation-Task handles (feat)
- `56e9acf` — T3: controllable fake `WeaponValidator` (test)
- `c8cf6d1` — T2: cancel-and-replace weapon/shield validation Tasks (fix)
- `663ee67` — T4: expand regression suite to AC-02/AC-05/AC-06 (test)
- plus an uncommitted stage-1 review fix (merge-on-write clear-by-omission bug, findings 1–2 in
  `_review/review-2026-08-06.md`) — **needs a commit before this PR opens**, see note below.

## Verification

- Unit: `xcodebuild test -scheme elf_Kit -destination 'platform=iOS Simulator,name=iPhone 17'` —
  510 XCTest + 14 Swift Testing tests, 0 failures (re-run at ship time, matches the review record).
- Integration: N/A — no integration layer for this dev-only ViewModel fix.
- Lint: `swiftlint --quiet` — 0 violations in any touched file (pre-existing warnings elsewhere, untouched).
- Ran the feature: exercised via the 5 `BattleSetupViewModelTests` cases directly driving
  `BattleSetupViewModel` against a controllable fake validator (deterministic release order, not
  wall-clock timing) — `testRapidSameSlotReselection_OnlyFinalSelectionIsApplied` (AC-01/AC-03/AC-04),
  `testSingleSelection_RejectionOutcomeIsAppliedInFull` (AC-02), `testUnequip_ClearsTheSlot` (AC-02
  clear-by-omission regression), `testCrossHeroSelections_DoNotInterfereWithEachOther` (AC-05),
  `testCrossSlotRapidSelection_BothOutcomesArePreserved` (AC-06). The dev Battle Setup screen itself
  was not driven live in the Simulator — this is a headless CLI environment with no interactive
  Simulator session available this run; the ViewModel-level tests are the actual behavior surface
  since the fix is UI-inert (confirmed by review's no-signal UI-class gate) and there is no
  screenshot-verifiable visual change.

## Operational notes

- Migration: none.
- Feature flag / config: none.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

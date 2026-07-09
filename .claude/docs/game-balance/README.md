# Game Balance — Index

All combat balance work, simulation results, and decision trail for the
elf RPG combat triangle (crit / def / dodge fight styles).

## Entry points

- **Live source of truth (latest state + open questions):**
  [`balance-task-2026-05-26.md`](balance-task-2026-05-26.md) — main task
  document. Round-39 baseline + Session 2 refactors / decisions / scorecards.
- **Mechanics reference:** `../attributes.md` (single source of truth on
  current code state — formulas, distributions, constants).
- **Legacy mechanics archive:**
  [`attributes-legacy-archive.md`](attributes-legacy-archive.md) — pre-Session-2
  combat math, Round-39 win-rate sweeps, per-point-value tables and the original
  EP design plan, split out of `../attributes.md` (2026-07-09). Historical only.

## Session 2 snapshots (2026-05-27 → 2026-06-01)

Each file is a frozen simulation snapshot taken right after a specific
change. Reading them in order tells the story of what was tried, what
worked, what regressed.

| Date | File | Headline |
|------|------|----------|
| 2026-05-28 | [`triangle-sweep-session2-sqrt-curve-2026-05-28.md`](triangle-sweep-session2-sqrt-curve-2026-05-28.md) | Mid-session triangle baseline after sqrt strength curve + Option C INT reduction |
| 2026-06-01 | [`attribute-strategy-choice-2026-06-01.md`](attribute-strategy-choice-2026-06-01.md) | Player-choice exploration — what if players could pick where bonus points go |
| 2026-06-01 | [`blocks-lost-per-str-01-2026-06-01.md`](blocks-lost-per-str-01-2026-06-01.md) | `blocksLostPerAttackerStrength 0.2 → 0.1` experiment |
| 2026-06-01 | [`dynamic-suppression-08-2026-06-01.md`](dynamic-suppression-08-2026-06-01.md) | Dynamic crit + dodge intuition suppression, base 0.8 |
| 2026-06-01 | [`attribute-comparison-2026-06-01.md`](attribute-comparison-2026-06-01.md) | Cross-cut synthesis: solo power × marginal value × class fit per attribute |

## Round-39 archive (2026-05-26)

Per-step snapshots from the original 39-round tuning pass leading up to
the "final balance" check-in. Useful as historical reference; superseded
by Session 2 for current code.

- `triangle-sweep-pre-endurance-reduction-2026-05-25.md`
- `triangle-sweep-post-endurance-reduction-step1-2026-05-25.md`
- `triangle-sweep-post-endurance-reduction-step2-2026-05-25.md`
- `triangle-sweep-post-crit-formula-change-step3-2026-05-25.md`
- `triangle-sweep-post-blocks-per-endurance-04-step4-2026-05-25.md`
- `triangle-sweep-post-30pct-hand-tuned-table-step5-2026-05-25.md`
- `triangle-sweep-post-exhausted-block-mechanic-step6-2026-05-26.md`
- `triangle-sweep-post-starting-ep-2400-step7-2026-05-26.md`
- `triangle-sweep-post-blocked-crit-weighted-step8-2026-05-26.md`
- `triangle-sweep-post-exhausted-block-multiplier-06-step9-2026-05-26.md`
- `triangle-sweep-post-weak-block-crit-semantic-step10-2026-05-26.md`
- `triangle-sweep-lvl-3-6-9-12-2026-05-24.md`
- `triangle-sweep-final-balance-2026-05-26.md`

## How to add a new snapshot

When running a balance simulation that produces noteworthy results:

1. Save the full results table + diff vs prior + verdict as a markdown
   file named `<topic>-<date>.md` in this folder.
2. Add a one-line entry to the relevant section above.
3. Add a `Headlines` block at the top of `balance-task-2026-05-26.md`
   pointing to the new snapshot.

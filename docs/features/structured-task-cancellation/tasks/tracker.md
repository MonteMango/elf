# Tracker — structured-task-cancellation

> Status of every task in the epic. `implement` updates `done` as it commits each task.
> States: `todo` · `in_progress` · `blocked` · `review` · `done`.

| # | Task | Layer | Owner | Estimate | Blocked by | Status |
|---|---|---|---|---|---|---|
| T1 | Add per-slot validation-Task handles to `HeroConfigurationState` | domain | Vitalii Lytvynov | S | — | done |
| T2 | Cancel-and-replace + merge-on-write in `updateSelectedItems` | domain | Vitalii Lytvynov | M | T1 | done |
| T3 | Controllable fake `WeaponValidator` test double | tests | Vitalii Lytvynov | S | — | done |
| T4 | Regression suite (rapid re-selection, cross-slot, cross-hero, neutrality) | tests | Vitalii Lytvynov | M | T2, T3 | done |

**Total:** 4 tasks, ~1 person-day (single PR, XS per `.size`).

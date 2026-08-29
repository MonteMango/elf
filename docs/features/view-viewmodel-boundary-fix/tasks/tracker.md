# Tracker — view-viewmodel-boundary-fix

> Status of every task in the epic. `implement` updates `done` as it commits each task.
> States: `todo` · `in_progress` · `blocked` · `review` · `done`.

| # | Task | Layer | Owner | Estimate | Blocked by | Status |
|---|---|---|---|---|---|---|
| T1 | Add `GameSession.completeDungeonRun()` with idempotent early return | domain | Vitalii Lytvynov | S | — | done |
| T2 | Add `GameDayViewModel.startDungeonRun()` with AP debit | app | Vitalii Lytvynov | M | — | done |
| T3 | Route `DungeonViewModel.finishRun()` through `completeDungeonRun()` | app | Vitalii Lytvynov | S | T1 | done |
| T4 | BattleResult companion VM + factory calling `completeDungeonRun()` | app | Vitalii Lytvynov | M | T1 | done |
| T5 | Move death-path reward banking into `BattleFightViewModel` | app | Vitalii Lytvynov | S | — | done |
| T6 | `FarmActivityViewModel`: `try?` → `saveInBackground()` | app | Vitalii Lytvynov | S | — | done |
| T7 | `GameDayStateViewModel.advanceToNextDay()` order + logging | app | Vitalii Lytvynov | M | — | done |
| T8 | `GameDayViewModel.exitGame()` order + logging | app | Vitalii Lytvynov | M | — | done |
| T9 | Wire `GameDayScreen` → `viewModel.startDungeonRun()` | ui | Vitalii Lytvynov | S | T2 | done |
| T10 | Wire `DungeonScreen` → `viewModel.finishRun()` | ui | Vitalii Lytvynov | S | T3 | done |
| T11 | Wire `BattleResultScreen` → companion VM | ui | Vitalii Lytvynov | S | T4 | done |
| T12 | Wire `BattleFightRouteView` off direct `bankDungeonRewardsOnDeath()` | ui | Vitalii Lytvynov | S | T5 | done |
| T13 | Document the anti-pattern in `common-mistakes.md` | docs | Vitalii Lytvynov | S | — | done |
| T14 | Fix death-path reward-banking order (review finding #1+#2) | app | Vitalii Lytvynov | S | T5, T12 | done |
| T15 | AC-02/AC-02b: navigate on `startDungeonRun()` return value, not `session.dungeonSession` (review finding #3) | app | Vitalii Lytvynov | S | T2, T9 | done |
| T16 | Remove orphaned `prepareDungeonRun()` (review finding) | app | Vitalii Lytvynov | XS | T15 | done |
| T17 | Correct `awaitInFlightSave()` overpromising comments (review finding) | app | Vitalii Lytvynov | XS | T7, T8 | done |
| T18 | Restrict hunt-battle's extra `saveInBackground()` pass (review finding) | app | Vitalii Lytvynov | XS | T5 | done |
| T19 | `SessionRouteView` falls back to `dismissModal()` on missing session (review finding) | ui | Vitalii Lytvynov | XS | — | done |
| T20 | Strengthen AC-01 "exactly once" test fixture (review finding) | app | Vitalii Lytvynov | XS | T2 | done |
| T21 | T14 test must prove real reward banking, not just call order (review-2026-08-26 #1) | app | Vitalii Lytvynov | S | T14 | done |
| T22 | Fix sad.md Flow 3 diagram — stale pre-fix order (review-2026-08-26 #2) | docs | Vitalii Lytvynov | XS | T14, T18 | done |
| T23 | Fix `finishBattle()` doc comment (review-2026-08-26 #3) | app | Vitalii Lytvynov | XS | — | done |
| T24 | Assert `startDungeonRun()` return value in AC-02/AC-02b tests (review-2026-08-26 #4) | app | Vitalii Lytvynov | XS | T15 | done |
| T25 | Wrap `BattleResultScreen`'s `#Preview` blocks in `#if DEBUG` — Release build fails (review-2026-08-26 round-2 #1) | ui | Vitalii Lytvynov | XS | T11 | done |
| T26 | Fix stale `BattleFightRouteView` reference in `continueAfterBattle()` comment (review-2026-08-26 round-2 #2) | ui | Vitalii Lytvynov | XS | T5, T12 | done |

**Total:** 26 tasks, ~1 person-day (XS feature, `quick` route) + 7 review follow-up tasks (T14–T20, from `_review/review-2026-08-24.md`) + 4 loop-back review follow-up tasks (T21–T24, from `_review/review-2026-08-26.md`; finding #5 — residual `BattleFightRouteView` facade calls — deferred to spec §8, not a task) + 2 round-2-review follow-up tasks (T25–T26, from `_review/review-2026-08-26-2.md`).

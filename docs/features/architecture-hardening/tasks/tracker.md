# Tracker — architecture-hardening

> Status of every task in the epic. `implement` updates `done` as it commits each task.
> States: `todo` · `in_progress` · `blocked` · `review` · `done`.

| # | Task | Layer | Owner | Estimate | Blocked by | Status |
|---|---|---|---|---|---|---|
| T1 | Capture pre-refactor perf baseline | tests | Vitalii Lytvynov | S | — | done |
| T2 | Fix the two AC-08 doc issues | docs | Vitalii Lytvynov | S | — | done |
| T3 | Resolve persistence/coordinator print-site disposition | wiring | Vitalii Lytvynov | M | — | done |
| T4 | Route the 9 confirmed print sites through the logger | app | Vitalii Lytvynov | M | — | done |
| T5 | Add the SwiftLint logging guard + allow-list | wiring | Vitalii Lytvynov | M | T3, T4 | done |
| T6 | DUP-1: collapse the 3 inventory-add methods | domain | Vitalii Lytvynov | S | — | done |
| T7 | Extract `RewardApplicationMutator` + invariant #1 test | domain | Vitalii Lytvynov | M | — | done |
| T8 | Extract `RosterProgressionMutator` | domain | Vitalii Lytvynov | M | — | done |
| T9 | Verify `BuffApplicationService` AC-06 compliance | tests | Vitalii Lytvynov | S | — | done |
| T10 | Extract `DayCycleMutator` | domain | Vitalii Lytvynov | M | — | done |
| T11 | Extract `DungeonLifecycleMutator` | domain | Vitalii Lytvynov | M | — | done |
| T12 | Extract `WorldTurnMutator` + invariant #2 test + `GameSession` convergence | domain | Vitalii Lytvynov | M | T6, T7, T8, T9, T10, T11 | done |
| T13 | Extract `RunProgressionMutator` | domain | Vitalii Lytvynov | M | — | done |
| T14 | Extract `RoomBattleRewardMutator` + `DungeonSession` convergence | domain | Vitalii Lytvynov | M | T13 | done |
| T15 | Extract `RoundExecutionMutator` | domain | Vitalii Lytvynov | M | — | done |
| T16 | Extract `DuelPairingMutator` | domain | Vitalii Lytvynov | S | — | done |
| T17 | `BattleFightViewModel+Display` split + convergence | ui | Vitalii Lytvynov | M | T9, T15, T16 | done |
| T18 | `AppRoute.gameSession` → `GameID` + destination resolution | ui | Vitalii Lytvynov | M | — | done |
| T19 | `AppRoute.calendar` → zero-payload + destination resolution | ui | Vitalii Lytvynov | M | — | done |
| T20 | Final gate: build + test + lint + perf regression | tests | Vitalii Lytvynov | S | T1, T2, T5, T12, T14, T17, T18, T19 | done |
| T21 | Review finding #1: extract `VitalsRescaleMutator`, drop `static` | domain | Vitalii Lytvynov | S | — | done |
| T22 | Review finding #2: facade-level AC-04 invariant #1 test | tests | Vitalii Lytvynov | S | — | done |
| T23 | Review finding #3: tighten `GameStore.player` to `internal(set)` | wiring | Vitalii Lytvynov | S | — | done |
| T24 | Review finding #7: add `logDebug`, unify `#if DEBUG` at the sink | app | Vitalii Lytvynov | S | — | done |
| T25 | Re-review finding: AC-05 automated test coverage (`SessionRouteView` resolve/pop-back) | ui | Vitalii Lytvynov | S | — | done |

**Total:** 25 tasks, ~17.5 person-days (T21–T24 added post-review, 2026-07-11; T25 added post-re-review, 2026-07-11).

## T1 — pre-refactor performance baseline

- Command: `xcodebuild test -scheme elf_Kit -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan battle_simulation_IntegrationTests`
- Test suite `BattleSimulationIntegrationTests` (5 tests) duration: **687.712 seconds**
- Commit: `5142ec38f91c027787e307a26885bf799b4fbab4`
- Recorded: 2026-07-10
- T20 must compare its post-refactor run of the same suite/command against this baseline within ±5% (≈653–722 s).

## T20 — final gate results (2026-07-10)

Gate outcome: **RED / blocked** — DoD not met. Diagnostic run only (no fixes; blocked upstream tasks remain).

- **Build** (`xcodebuild -scheme elf -destination 'platform=iOS Simulator,name=iPhone 17' build`): **BUILD SUCCEEDED**, but 16 SwiftLint warnings surfaced via the build phase → not "0 new warnings".
- **Unit tests** (`xcodebuild test -scheme elf_Kit …`): **TEST FAILED** — 3 failing tests:
  - `WorldTurnMutatorTests.testApplyWorldTurn_appliesExpDropsAndAP_whenSlotIdMatchesRoster` (T12, blocked)
  - `BattleFightViewModel_RoundExecutionAndDuelPairingDelegationTests.testExecuteFightRound_AppliesInjectedRoundResult` (T17, blocked)
  - `BattleFightViewModel_RoundExecutionAndDuelPairingDelegationTests.testExecuteFightRound_ReadinessGuard_DelegatesToMutator` (T17, blocked)
  - `BattleFightViewModel_RoundExecutionAndDuelPairingDelegationTests.testLoadInitialData_DelegatesToDuelPairingMutator` (T17, blocked)
- **Lint** (`swiftlint --strict`): **16 violations, 16 serious** → gate requires 0. No `no_print` logging guard present (T5 blocked). Violations are TODO / force_unwrapping / function_body_length / function_parameter_count / control_statement across DataLayer, UILayer, elf_iOS, and `ElfApp.swift`.
- **Perf** (`xcodebuild test -scheme elf_Kit … -testPlan battle_simulation_IntegrationTests`, same command as T1): **TEST SUCCEEDED**, 5 tests. Suite `BattleSimulationIntegrationTests` duration: **2234.556 s** vs baseline **687.712 s** → **+224.9%**, far outside the ±5% window (653–722 s). NOTE: a ~3.25× slowdown is anomalous for these refactors and likely reflects environmental factors (thermal state / background load / build config) as much as code; a re-run on an idle, thermally-stable machine is recommended before treating it as a pure code regression.

Gate blockers to clear before T20 can go green: T4, T5, T11, T12, T13, T17 (and re-validate the perf number).

## Post-workflow remediation (2026-07-10)

The dynamic-Workflow run (20 tasks, in-place/no-worktree parallelism per this session's deviation from `isolation: worktree`, since worktrees would not see this feature's uncommitted design docs) hit 3 connection-drop errors on subagents (`review:T11`, `red:T17`, `green:T12`) after ~10.8h and finished with an honest-but-stale T20 RED report. A follow-up ground-truth pass (direct `xcodebuild`/`swiftlint` runs, not agent self-reports) found the real state differed from the agents' own summaries in several places, and fixed:

- **T4** — real AC-01 regression: the print→logger swap dropped the `#if DEBUG` guard on 2 of the 9 sites (`GameSession.swift:437`, `DefaultDungeonRewardCalculator.swift:29`) that were `#if DEBUG`-gated in the original code (the other 7 sites, e.g. the `CharacterCreation`/`GameDay` ViewModels, were never gated originally, so leaving `logError` itself ungated is correct for those). Fix: re-added `#if DEBUG`/`#endif` around just those 2 call sites — restores exact pre-refactor behavior everywhere.
- **T5** — the `raw_print_banned` custom rule itself works correctly (0 violations from it). `swiftlint --strict` still reports 16 violations repo-wide, but all are pre-existing, feature-unrelated debt (TODO / force_unwrapping / function_body_length / function_parameter_count / control_statement in files this feature never touches, e.g. `ElfApp.swift`, `CombatantSnapshot.swift`). **Decision (user, 2026-07-10): T5/T20's lint gate means 0 *new* violations, not 0 repo-wide** — the 16 pre-existing ones are out of scope and left as-is (not silently fixed, not silently ignored — tracked here).
- **T11** — code was already fully green (`gate_green: true`); only the independent-review subagent hit the connection error. Spot-checked the `GameSession` → `DungeonLifecycleMutator` delegation directly (all 6 lifecycle methods reduce to 1-line calls) — confirmed correct, no code change needed.
- **T12** — `WorldTurnMutatorTests.testApplyWorldTurn_appliesExpDropsAndAP_whenSlotIdMatchesRoster` was failing for a **test bug**, not a production bug: `DefaultRosterProgressionMutator.addDrops` resolves `@Dependency(\.inventoryService)` lazily at call time (by design, documented in its own header), but the test only had the `withDependencies` override active around *obtaining* the mutator reference, not around the `applyWorldTurn` call itself — so the override had already gone out of scope. Fixed by moving the call inside the `withDependencies` operation closure (matching the working `RosterProgressionMutatorTests` precedent).
- **T13** — the build error the agent hit (`AppCoordinator.swift:104` missing explicit `self`) was transient concurrent-edit noise from the shared (non-worktree) working tree; the current file already has `self.debugGameLogger...` and a clean `xcodebuild -scheme elf build` no longer reproduces it. No code change needed.
- **T17** — same root cause as T12, in 3 tests: `BattleFightViewModel`'s new test file (`BattleFightViewModel_RoundExecutionAndDuelPairingDelegationTests.swift`, the first test in the repo to construct a full `BattleFightViewModel`) needed test values for **all** of the VM's dependencies (`botAI`, `battleLogger`, `buffEffectsCalculator`, `equippedSlotResolver`, `equipmentQueryService`, `duelPairingService` — none of which have a `testValue`, only `liveValue`, by repo convention), and the `loadInitialData()`/`executeFightRound()` calls needed to run *inside* the `withDependencies` scope, not after it returned. Fixed by adding the 6 missing overrides and moving the VM interaction inside each `operation:` closure.

**Ground truth after remediation:** `xcodebuild -scheme elf build` → BUILD SUCCEEDED. `xcodebuild test -scheme elf_Kit` → **498/498 tests pass, 0 failures**. `swiftlint --strict` → 16 violations, all pre-existing/out-of-scope (0 new). Perf re-measured clean (idle machine, no concurrent agents): `BattleSimulationIntegrationTests` = **693.460 s** vs T1 baseline **687.712 s** → **+0.84%**, well within the ±5% window (653–722 s). Confirms the earlier +224.9% reading from the chaotic 10.8h parallel run was environmental (thermal/resource contention), not a code regression.

## T20 — final gate results, remediated (2026-07-10)

Gate outcome: **GREEN**. All 20 tasks done.

- **Build**: BUILD SUCCEEDED, 0 errors, 0 new warnings.
- **Unit tests**: 498/498 pass, 0 failures.
- **Lint** (`swiftlint --strict`): 16 violations, all pre-existing and outside this feature's scope (0 new violations; the `raw_print_banned` guard itself reports 0). Per user decision, T5/T20's lint gate is "0 new violations," not "0 repo-wide" — the 16 are tracked as separate, unrelated tech debt.
- **Perf**: `BattleSimulationIntegrationTests` = 693.460 s vs baseline 687.712 s (+0.84%), within ±5%.

## Re-verification after context reset (2026-07-11)

A fresh `/sdd:implement architecture-hardening` invocation (new session, no memory of the prior run) re-ran ground truth against the still-uncommitted working tree: `xcodebuild -scheme elf build` → BUILD SUCCEEDED; `xcodebuild test -scheme elf_Kit` → 498/498 pass, 0 failures; `swiftlint --strict` → 16 violations, unchanged set, all pre-existing/out-of-scope. Perf suite not re-run (already reverified above; ~12 min cost not repeated). No code changes were needed — all 20 tasks confirmed still done in-place.

## T21–T24 — review follow-up fixes (2026-07-11)

`_review/review-2026-07-11.md` gated **CHANGES REQUESTED** on 4 "Fix now" findings (#1, #2, #3, #7). Registered as T21–T24 and driven through the full TDD cycle (RED → GREEN → GATE) per task; no code was committed (project git policy), all changes sit in the working tree.

- **T21** (finding #1) — `BattleFightViewModel.rescaleCurrentVitals`/`scaledVital` extracted into a new injected `VitalsRescaleMutator` (`DataLayer/Services/VitalsRescale/`, protocol + `Default*` + `+Dependency.swift` triad). `scaledVital` is no longer `static` anywhere. The 8 prior `BattleFightViewModelTests.scaledVital` cases moved to `VitalsRescaleMutatorTests` (now driven through the public `rescaleVitals(combatant:before:after:)`, plus a 9th MP-channel case); a new `BattleFightViewModel_VitalsRescaleDelegationTests` proves `applyBattleBuff` delegates for real (spy sentinel values the real formula could never produce). `BattleFightViewModelTests.swift`'s old file was removed (fully superseded).
- **T22** (finding #2) — Added `testConcludeHuntBattle_RealMutatorAndCalculator_ReportsPreMutationExpAsPreviousExp` to `GameSession_RewardApplicationDelegationTests`, driving `concludeHuntBattle` through the **real** `DefaultRewardApplicationMutator` + **real** `DefaultBattleResultCalculator` (huntService/dropService swapped for deterministic fixed doubles; `progressionService` is the real `ElfProgressionService`, pure math). Sanity-verified the test actually catches a reordering bug (temporarily inserted an early `addPlayerExperience(1)` before the mutator call — test failed 121≠120 as expected — then reverted). Hit and resolved the project's known "outer/nested `withDependencies`" gotcha: `DefaultBattleResultCalculator()` must be constructed inside an `operation:` closure, not the setup closure still building overrides, or it captures the wrong ambient dependencies.
- **T23** (finding #3) — `GameStore.player`'s setter narrowed from `public` to `internal` (`public internal(set) var player`), matching `currentDay`/`calendar`/`houses`/`actionPoints`. Confirmed via full `elf` build (compiles = no `elf_iOS` call site was writing through it) plus a new source-content pin test (`GameStoreAccessControlTests`).
- **T24** (finding #7) — Added `DebugGameLogger.logDebug(_:)` for non-error traces (Console prints `ℹ️`, gated `#if DEBUG` at the sink; NoOp no-ops). Moved `CharacterCreationViewModel`'s success trace and `GameDayViewModel`'s 3 UI-tap traces off `logError` onto `logDebug`. Moved the `#if DEBUG` guard into `ConsoleDebugGameLogger.logError`/`logDebug` bodies and removed the now-redundant call-site guards in `GameSession.swift` and `DefaultDungeonRewardCalculator.swift`. `LoggerRoutingTests` extended with 3 new source-content checks.

**Ground truth after T21–T24 (2026-07-11):** `xcodebuild -scheme elf build` → BUILD SUCCEEDED (per-task, re-verified after each). `xcodebuild test -scheme elf_Kit` → 505/505 pass, 0 failures. `swiftlint --strict` → 16 violations, same pre-existing/out-of-scope set (0 new). Findings #4, #5, #6, #8 required no further action (already dismissed/deferred/fixed per the review record).

## T25 — re-review follow-up fix (2026-07-11)

`_review/review-2026-07-11.md`'s remaining open finding: AC-05's `SessionRouteView` match/mismatch decision (`SessionRouteView.swift:33-43`) had no automated test coverage — no SwiftUI view-hosting harness exists in `Packages/elf_iOS/Tests`, so the View body itself was untestable. Extracted the decision into a pure, non-`static` free function `sessionMatchesExpectedGameId(sessionGameId:expectedGameId:)` (a `nil` `expectedGameId` — the `.calendar` case — always matches; otherwise the session's `GameID` must equal it) and had `body` call it instead of inlining the `if let expectedGameId, session.state.gameId != expectedGameId` check. Added `SessionRouteViewTests.swift` (3 cases: matching GameID renders, mismatched GameID triggers the AC-05 pop-back path, nil `expectedGameId` always matches — covering `.calendar`'s direct-resolution/no-gating behaviour). `AppRouteTests.swift` unchanged and still passing.

Ran RED first (`cannot find 'sessionMatchesExpectedGameId' in scope` — confirmed GOOD red) before extracting the function.

Note: `elf_iOSTests` has no committed Xcode scheme reachable from the top-level `elf.xcodeproj` (only `elfTests`/`elfUITests`, the native app's own targets, are wired into the `elf` scheme's `TestAction`); it only runs via `cd Packages/elf_iOS && xcodebuild test -scheme elf_iOS -destination 'platform=iOS Simulator,name=iPhone 17'` (SPM auto-generates a scheme from `Package.swift`). Documented here since this is the only route to exercise `AppRouteTests`/`SessionRouteViewTests` — a pre-existing gap, not something T25 changed.

**Ground truth after T25 (2026-07-11):** `xcodebuild -scheme elf build` → BUILD SUCCEEDED. `xcodebuild test -scheme elf_Kit` → 505/505 pass, 0 failures. `cd Packages/elf_iOS && xcodebuild test -scheme elf_iOS` → 6/6 pass (3 `AppRouteTests` + 3 new `SessionRouteViewTests`), 0 failures. `swiftlint --strict` → 16 violations, same pre-existing/out-of-scope set (0 new). All 25 tasks now done.

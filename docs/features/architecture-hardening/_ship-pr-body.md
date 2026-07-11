## Summary

Behaviour-neutral consistency-and-surgery pass: delegates the domain rules inline in `GameSession`/`DungeonSession`/`BattleFightViewModel` to 11 small DI-injected mutators, routes all ViewModel logging through the logger abstraction with a mechanical lint guard, converts the two resolvable navigation routes (`.gameSession`, `.calendar`) off carrying full domain models, collapses three duplicate inventory-add methods, and closes a facade-mutation gap on `GameStore.player`. See [spec](docs/features/architecture-hardening/spec.md).

## Acceptance criteria

- AC-01 — build/test/lint green, behaviour-neutral ✓
- AC-02 — raw-print lint gate blocks and explains ✓
- AC-03 — `GameStore.player` facade-only mutation (no direct UI-layer write path compiles) ✓
- AC-04 — reward-application ordering + world-turn roster-reshuffle invariants, each pinned by a named regression test ✓
- AC-05 — `.gameSession`/`.calendar` resolve at destination; stale `GameID` pops back ✓
- AC-06 — 11 genuine mutator extractions, each a separate injected type with its own test ✓
- AC-07 — hand-written equality collapsed to one identity/always-true branch per converted case (corrected wording, see spec) ✓
- AC-08 — stale doc comment removed, platform line synced ✓
- AC-09 — inventory-add methods collapsed to one core path + shims ✓

## Design

- Spec: `docs/features/architecture-hardening/spec.md`
- Architecture: `docs/features/architecture-hardening/sad.md`
- Decisions: `docs/features/architecture-hardening/adr/`
- Test plan: `docs/features/architecture-hardening/test-plan.md`

## Tasks

T1–T20 (initial implementation) + T21–T24 (review follow-up: `VitalsRescaleMutator` extraction, non-tautological AC-04 test, `GameStore.player` access tightening, logging severity/gating fix) + T25 (AC-05 test coverage for `SessionRouteView`'s match/pop-back decision). Full history in `docs/features/architecture-hardening/tasks/tracker.md`.

## Verification

- Unit (`elf_Kit`): 505/505 pass (re-confirmed independently at ship time).
- Unit (`elf_iOS`): 6/6 pass (re-confirmed independently at ship time).
- Build (`elf` scheme, iPhone 17 simulator): BUILD SUCCEEDED (re-confirmed independently at ship time).
- Lint (`swiftlint --strict`): 16 pre-existing/out-of-scope violations, 0 from `raw_print_banned`, 0 new from this feature.
- Ran the feature: this is an internal, behaviour-neutral refactor with no new user-facing surface, so "running the feature" = re-deriving each AC's outcome from the changed code directly (not just trusting green tests) — spot-checked AC-03 (`GameStore.swift:50`, `public internal(set) var player`), AC-05 (`SessionRouteView.swift`'s `sessionMatchesExpectedGameId` gating render-vs-pop), AC-06 (no `static` left in `BattleFightViewModel`; mutators are separate injected types), and AC-09 (`GameSession.swift:229-246`, three shims delegating to one `addMaterialsToInventory` core path) directly against current code. Three independent `sdd:reviewer` rounds already traced all 9 ACs end-to-end (spec → sad.md §6 → tasks.json → code + test) — see `docs/features/architecture-hardening/_review/review-2026-07-11.md`, gate result: **PASS**.

## Operational notes

- Migration: none.
- Feature flag / config: none — `raw_print_banned` SwiftLint rule active by default with an allow-list (logger implementations, design-system leaf module, dev tools).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

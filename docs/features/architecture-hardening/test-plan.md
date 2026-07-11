---
status: Draft
owner: "Vitalii Lytvynov"
reviewers: ["Vitalii Lytvynov"]
updated_at: "2026-07-10"
feature_size: "L"
---

# Test plan — architecture-hardening

Behaviour-neutral consistency-and-surgery bundle (session facades → orchestrators over injected mutators, `AppRoute` route slimming, logging-guard, doc fixes, DUP-1 collapse) — every test below proves either "nothing observable changed" or "the new guard actually holds the line".

## Levels

`sad.md` frontmatter declares `target_surfaces: [mobile-app]` → adds Component + E2E-through-UI (no Visual-regression — mobile, not web).

| Level | Scope | Strategy (generic — no tool names) |
|---|---|---|
| Unit | Pure logic: a mutator's rule, the inventory-add core path, `AppRoute` `Hashable`/`Equatable` synthesis, the doc-consistency check. | In-memory, no external dependency; `@Dependency` test values for anything the mutator needs. |
| Integration | A session facade (`GameSession`/`DungeonSession`) or `BattleFightViewModel` exercised against its real injected mutators end to end (not mocked out), through the existing save/DI stack. | Real mutator implementations wired via the project's DI container; a real (in-memory or tmp-dir) save file where persistence is touched — no mocked domain logic. |
| Contract | <!-- N/A: no API/event boundary between two participants — this feature has no HTTP/event contract (spec §6.1: no network surface). --> | — |
| E2E | A full critical-flow story exercised end to end (session → mutator → save → result). | The flow driven through its real entry point (the session facade method or ViewModel action) against the real save stack, no UI. |
| Load | NFR validation for the runtime-performance NFR only. | The load mechanism already in the repo for `battle_simulation_IntegrationTests` — a timed integration-test run, not a dedicated load tool. |
| Component *(mobile-app)* | The navigation-destination view resolving `.gameSession`/`.calendar` in isolation. | Render/construct the destination view with a given route case + session state; assert what it resolves, no full app boot. |
| E2E-through-UI *(mobile-app)* | The navigation push/pop/re-push flow for `.gameSession` and `.calendar`, driven through the real `NavigationStack`. | Drive `AppCoordinator`/`NavigationStack` push/pop calls against a real session; assert de-dup and the mismatch-fallback pop-back. |

## AC coverage

| AC (spec.md §5) | Test name (intent-based) | Level | Expected outcome |
|---|---|---|---|
| AC-01 — happy path | full existing `elf_Kit` suite passes unmodified after the reshape | Unit + Integration (whole suite, T20 gate) | 0 build errors, 0 new warnings, every pre-existing test still passes, `swiftlint --strict` is clean |
| AC-02 — raw print blocked | a raw `print(` introduced in a non-allow-listed ViewModel/service is rejected by lint | Integration (real SwiftLint run against a scratch file) | lint fails with a message explaining logging must go through the logger dependency |
| AC-02 — allow-listed paths stay clean | allow-listed paths (`elf_SwiftUI`, `Dev/`, `Diagnostics/`, logger implementations, `ElfApp.swift`) keep compiling with `print(` present | Integration (real SwiftLint run) | lint passes — allow-list does not over-block |
| AC-03 — facade-only mutation compiles | UI-layer code cannot mutate `GameSession`/`DungeonSession` state directly (only via facade methods) | Unit (negative-compile check — attempted direct mutation from outside the module fails to build) | does not compile; only facade methods remain the write path |
| AC-04 — reward-application invariant | reward result is computed against pre-mutation exp/inventory state in `RewardApplicationMutator` | Unit | result matches values captured *before* the mutation; fails if computed after |
| AC-04 — roster-reshuffle guard | `WorldTurnMutator` rejects/guards a mid-resolution roster change | Unit | the guard fires; the roster is not silently mutated mid `applyWorldTurn` |
| AC-04 — reward-application invariant holds facade-to-facade | `GameSession.concludeHuntBattle` end to end still applies rewards against pre-mutation state after delegation | Integration | same observable reward result as pre-refactor baseline |
| AC-05 — `.gameSession` resolves by GameID | destination screen resolves `Game` from the session by the route's `GameID` | Component + E2E-through-UI | the correct `Game` is shown when the ID matches the active session |
| AC-05 — `.gameSession` mismatch fallback | route's `GameID` no longer matches any session (session ended/replaced) | Component + E2E-through-UI | destination silently pops back to the previous screen, no crash |
| AC-05 — `.calendar` resolves from session | destination screen resolves calendar + current day directly from the session (zero-payload case) | Component | calendar/current-day shown match the session's live state |
| AC-06 — `RewardApplicationMutator` is real delegation | mutator is a separate injected type (not an extension) with its own unit test; `GameSession` method reduces to one delegating call | Unit + reading the diff (structural check, not a runtime test) | mutator's own tests exist and pass; facade method body is a single call |
| AC-06 — `RosterProgressionMutator`/`DayCycleMutator`/`WorldTurnMutator`/`RoomBattleRewardMutator`/`RunProgressionMutator`/`DuelPairingMutator`/`RoundExecutionMutator` are real delegation | same delegation criteria per mutator (T8/T10/T12/T14/T13/T16/T15) | Unit (one per mutator) + reading the diff | each mutator has its own independent unit test; each facade/ViewModel method is a single delegating call |
| AC-06 — `BuffApplicationService` still satisfies AC-06 | both call paths (`GameSession.applyGlobalBuffToPlayer`/`applyGlobalBuff`, `BattleFightViewModel.applyBattleBuff`) are covered by the service's own test | Unit | both paths covered; gap closed if either was untested (T9) |
| AC-06 — `GameSession`/`DungeonSession` convergence | after all mutators land, no inline domain-rule mutation remains in the facade outside the persistence exception | reading the diff (structural check, T12/T14) | convergence check passes; no leftover inline rule logic |
| AC-07 — `.gameSession` de-dup matches prior `Game.id` comparison | synthesized `Hashable` on `GameID` payload | Unit | two routes with the same `GameID` are equal/de-dup exactly as the prior `Game.id`-based equality did |
| AC-07 — `.calendar` de-dup matches prior "always equal" behaviour | zero-payload `.calendar` case | Unit | any two `.calendar` pushes are equal; hand-written equality code is gone |
| AC-07 — push/pop/re-push behaviour unchanged | navigation stack exercised with real push/pop/re-push for both converted routes | E2E-through-UI | de-dup behaviour identical to pre-conversion for both routes |
| AC-08 — doc fixes applied | `GameStore.swift`'s stale `DefaultGameService` comment is gone; `CLAUDE.md`'s platform line matches `Package.swift`'s `.iOS(.v18)` | Unit (a file-content assertion / consistency check) | comment absent; platform line reads `iOS 18+` in both places, matching the package declaration |
| AC-09 — inventory-add shims preserve signatures and behaviour | `addFishToInventory`/`addHerbsToInventory`/`addOresToInventory` each call the single core add path | Unit | each shim's result (inventory state after collecting fish/herb/ore) is identical to its pre-collapse behaviour; all three signatures unchanged at every call site |

## Edge cases / error paths

- `.gameSession` route pushed with a `GameID` that no longer matches any live session (session ended or replaced) → expected: silent pop back to the previous screen, no crash (AC-05).
- A raw `print(` inserted in a file with no logger dependency but not on the allow-list → expected: lint blocks it with the plain-language message (AC-02).
- A raw `print(` inserted in an allow-listed path (e.g. `Packages/elf_SwiftUI/**`, `Packages/elf_iOS/Sources/Screens/Dev/**`) → expected: lint passes, no false positive (AC-02).
- `applyWorldTurn` invoked with a roster mutation attempted mid-resolution → expected: the reshuffle guard catches it, matching pre-refactor behaviour (AC-04).
- Direct UI-layer mutation attempt on `GameSession`/`DungeonSession` state (bypassing the facade) → expected: build failure, not a runtime error (AC-03).
- Each of the three inventory-add shims called with an empty ref list → expected: same no-op behaviour as before the collapse (AC-09, boundary case implied by "existing tests pass unchanged").

## Test data

- Seed strategy: existing `elf_Kit` test fixtures/factories for `Game`, `GameSession`, `DungeonSession`, roster/inventory state — no new entity shapes are introduced (`data-model.md`: no schema change), so no new factories are needed beyond what mutator extraction requires for isolated unit tests of each mutator.
- Integration dependency: the project's real DI container wiring real mutator implementations (not mocked domain rules); where persistence is touched, the existing `FileGameSaveStorage` actor against a throwaway save location — never a mocked save store.
- Cleanup boundary: per-test — each test constructs its own `GameSession`/`DungeonSession`/mutator instance via DI test values; no shared mutable fixture across tests, matching the existing suite's convention.

## NFR validation (load)

- **NFR: runtime performance, no regression** — `battle_simulation_IntegrationTests` duration stays within ±5% of the pre-change baseline. Scenario: T1 captures the baseline duration (with commit sha + date) *before* the first refactor PR lands; T20's final gate re-runs the same integration test post-refactor and asserts the new duration is within ±5% of the recorded baseline. Tool: the load mechanism already in the repo (a timed `xcodebuild test` run of `battle_simulation_IntegrationTests`) — no dedicated load tool needed for a single-scenario timing NFR.

## CI placement

- On every PR: Unit (all mutator/route/doc-consistency tests), Integration (facade end-to-end tests), Component (route-destination resolution), lint (`swiftlint --strict`).
- On the final-gate task (T20) / pre-release: full E2E-through-UI navigation pass, `battle_simulation_IntegrationTests` timing comparison against the T1 baseline, full build + full existing suite.

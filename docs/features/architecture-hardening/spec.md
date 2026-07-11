---
status: Draft
owner: "Vitalii Lytvynov"
reviewers: ["Tech Lead"]
updated_at: "2026-07-09"
feature_size: "L"
---

# Spec — architecture-hardening

> **Glossary:** None — no `CONTEXT.md` exists. The single actor is the **Developer / Maintainer** (the solo dev who reads, edits, extends this code and runs the toolchain). No invented `user`/`admin`.
> **Reference material used:** `architecture-review.md` (detailed audit, 11 findings, phased plan) · `architecture-review-summary.md` (deep-research: don't migrate architecture, do targeted surgery) · `docs/architecture-map.md` (current architecture). Ideation pass (strategist / analyst / devils-advocate) informed §1 ¶3–¶4 and §8; not cited as inputs.

## 1. Context

**¶1 — What we're solving, for whom.** Elfy's codebase is strong but *uneven*: outstanding patterns (invariant-bearing value types, auto-composing dependency injection, project-wide typed IDs) sit next to a lagging "floor" — a session god-object that grows without bound, navigation routes that carry whole domain models plus ~72 hand-maintained equality lines, logging that bypasses the project's own logger abstraction with raw `print`, and three near-duplicate inventory-add methods. The beneficiary is the **Developer / Maintainer** — the solo developer who has to find, read, safely change and extend this code. The task is to *raise the floor to the ceiling*, not to rewrite.

**¶2 — Why now.** The god-object growth the audit predicted has already materialised: the primary game-session type went from 251 → ~560 LOC (×2.2) after a *single* dungeon-rewards feature bolted five new methods onto it. This is the unbounded-growth pattern the review warned about — every future feature adds another method to the facade and another hand-written equality case to the routes. The debt is cheap and reversible to pay down now (folders and thin services), entangling and risky to unpick later once more features lean on the same shapes.

**¶3 — The committed approach.** A **strictly behaviour-neutral consistency-and-surgery bundle**, with *no* premature feature-module extraction: (a) quick correctness/consistency fixes — remove a stale doc comment, sync the platform declaration in project docs, collapse the three duplicate inventory-add methods (`addFishToInventory` / `addHerbsToInventory` / `addOresToInventory` on `GameSession`) into one core add path with thin typed shims preserving each call site's signature (see AC-09); (b) route ViewModel logging through the existing logger abstraction and add a mechanical lint guard so it cannot silently return; (c) reduce the two session god-objects — `GameSession` (`Packages/elf_Kit/Sources/DataLayer/Sessions/GameSession.swift`, currently 564 LOC) and `DungeonSession` (`.../Sessions/DungeonSession.swift`, currently 365 LOC) — and the largest battle ViewModel — `BattleFightViewModel` (`Packages/elf_Kit/Sources/UILayer/BattleFight/BattleFightViewModel.swift`, currently 422 LOC) — to thin *orchestrating* units that delegate domain rules to small injected mutators, **grouped by domain-rule family** (e.g. one mutator for the reward-application group, one for the post-collapse inventory-add family) rather than one mutator per method (see AC-06 for the checkable delegation rule); (d) convert the **two resolvable** navigation routes in `Packages/elf_iOS/Sources/Navigation/AppRoute.swift` — `.gameSession(Game, playTime:)` → a `GameID`-based typed payload, and `.calendar(calendar: [GameDay], currentDayNumber:)` → a **zero-payload** case (`case calendar`) resolved from the session at the destination screen, following the same pattern already used by `.hunt`/`.farm`/`.craft`/`.questList` — and drop their hand-written equality (the battle routes `.battleFight`/`.autoBattleResult`/`.multiBattleResult`, carrying `Battle`, stay out of scope per §3). The ideation pass (strategist + analyst) independently favoured this floor-plus-surgery bundle over both a quick-wins-only slice and a go-big feature-module extraction — the latter is called *premature* by both source documents (no build-friction, cascade, or team trigger has fired).

**¶4 — Traceability & a load-bearing caveat.** Grounded in `architecture-review.md` + `architecture-review-summary.md`. **Caveat:** both are a snapshot dated 2026-06-08 and a clean-context verification against current code found several premises already stale, which directly shaped this scope: the silent-save-failure fix (E-1) targets a ViewModel save path that **no longer exists** (the real save is a coalesced *background* task with no synchronous ViewModel owner) → **E-1 is deferred** (see §3); the navigation-route equality is *semantically load-bearing* for `.calendar` (it deliberately compares by array-count + day-number, not identity) — resolved by converting `.calendar` to a **zero-payload** case instead of a typed-ID, so its equality trivially matches itself and the semantic-loss risk does not arise; `.gameSession`'s current equality already compares by `Game.id`, so converting it to a `GameID` payload changes nothing observable → **the two routes with a resolution home are `.gameSession` and `.calendar`**; **FYI, out of scope:** `.gameSession`'s `playTime: TimeInterval` parameter appears unread by any current call site (`AppRoute.view()` ignores it, `GameDayScreen.swift` never reads it) — left as-is, flagged here so it isn't lost, not fixed by this bundle; the session factories are **already** in separate files, so raw line-count is *not* the decoupling metric → the done-bar is *real delegation* (see AC-06 for the checkable rule), not LOC relocated into more extensions; the logging lint rule needs a broader allow-list than logger files alone (a leaf design-system module and dev tools also print). `design` and `tasks` **must re-verify every count and target against current code** before implementing — except `GameSession` = 564 LOC, `DungeonSession` = 365 LOC, and `BattleFightViewModel` = 422 LOC, which this `clarify` pass already confirmed current on 2026-07-09 by direct file inspection (see §7).
<!-- Decision override bullets (from critic Override resolutions) land here. -->

## 2. Goals

- **Raise the consistency floor** so the weakest areas — logging discipline, session god-object growth, and domain state placement in navigation — match the codebase's strongest patterns, measured by the §7 KPIs.
- **Make the raised floor self-defending** — a mechanical guard prevents the logging regression from silently returning, so the improvement survives future features without manual vigilance.
- **Change structure without changing behaviour** — the game and its existing test suite behave identically before and after; every refactor in scope is behaviour-neutral.

## 3. Non-goals

- **No SPM feature-module extraction** (e.g. a separate combat/dungeon package) — both source documents call it premature for a solo pre-ship project with zero build-friction; it buys load-bearing boundary risk for near-zero current benefit.
- **No player-facing save-failure surfacing (E-1)** — deferred to its own feature, because the real save path is a coalesced background task with no synchronous owner, and correlating "which save failed" needs a dedicated contract that this behaviour-neutral bundle should not smuggle in.
- **No battle-route ID migration / battle store** — the battle routes carry an ephemeral battle object with no store to resolve an ID against; introducing one is new stateful architecture outside this slice.
- **No player-index rework, bootstrap-contract change, or broad ViewModel test backfill** (findings M-1 / B-1 / TEST-1) — separate or ongoing work, not this slice; opportunistic ViewModel tests are allowed where a refactor already touches a ViewModel.
- **No repo-wide documentation/comment audit** — AC-08 covers exactly two already-identified items (the stale doc comment, the platform-declaration line); auditing every comment in the codebase for staleness is out of scope for this bundle.

## 4. User stories

### US-01: Keep the largest types small
**As a** Developer / Maintainer
**I want** the session facades and the largest ViewModel kept small and single-purpose
**So that** I can locate and change the right code without scanning a 500-line file.

### US-02: Consistent, silenceable logging
**As a** Developer / Maintainer
**I want** all ViewModel logging to go through the logger abstraction
**So that** output can be silenced or redirected in tests and release instead of leaking to the console.

### US-03: Trust that a refactor changed nothing
**As a** Developer / Maintainer
**I want** every structural change to keep the existing test suite green
**So that** I can refactor confidently, knowing observable behaviour and gameplay are unchanged.

### US-04: Clean navigation state
**As a** Developer / Maintainer
**I want** the two resolvable navigation routes (`AppRoute.gameSession`, `AppRoute.calendar`) to carry no full domain model — a typed ID where one is meaningful, or no payload at all where the destination can resolve everything from the session — and resolve their entity at the destination
**So that** I stop hand-maintaining equality code and stop placing whole domain models inside navigation state.

### US-05: A facade that orchestrates, not implements
**As a** Developer / Maintainer
**I want** the session types to delegate domain rules to small injected mutators
**So that** the facade stops accruing unbounded inline logic and each rule lives in one testable place.

### US-06: A guard that holds the line
**As a** Developer / Maintainer
**I want** a mechanical rule that rejects raw logging where a logger is available
**So that** the logging-consistency win cannot silently drift back in a future change.

### US-07: Docs that match reality
**As a** Developer / Maintainer
**I want** project docs and code comments to match the actual platform and types
**So that** I am not misled by a stale comment or an out-of-date platform line.

## 5. Acceptance criteria

### AC-01 (US-01, US-03) — happy path
**Given** the Developer has completed the in-scope structural changes
**When** they build, run the existing unit tests, and lint
**Then** the build compiles with no new warnings, every existing test passes unchanged, and lint is clean — confirming the change is behaviour-neutral and complete.

### AC-02 (US-02, US-06) — error / invalid input blocked
**Given** the logging guard is in place
**When** the Developer introduces a raw print statement in a ViewModel or service that has a logger available
**Then** the lint gate blocks it and explains in plain language that logging must go through the logger abstraction, not a raw print.

### AC-03 (US-05) — authorization / access denied
**Given** game and session state is mutation-gated (writable only inside the core module, exposed read-only outward)
**When** code in the UI layer attempts to mutate session state directly instead of going through the session facade
**Then** the module access rules deny it — it does not compile — so the refactor preserves facade-only mutation as the single write path.

### AC-04 (US-03, US-05) — domain invariant violation
**Given** two named ordering/state invariants — (1) the reward-application flow's "compute the result against the current values *before* the mutation runs" invariant, and (2) the world-turn roster-reshuffle guard (preventing the party roster from being reshuffled mid world-turn resolution)
**When** a mutator is extracted from the session facade for either invariant's logic
**Then** each invariant is preserved and covered by its own named regression test — written *before* that invariant's mutator is extracted — that fails if its guarded ordering/state is violated.

### AC-05 (US-04) — cross-context dependency
**Given** a resolvable navigation route carries no full domain model — `.gameSession` carries a `GameID`, `.calendar` carries no payload at all
**When** the destination screen is presented
**Then** for `.gameSession` it resolves the `Game` from the session (a separate context) by `GameID`, and for `.calendar` it resolves the calendar + current day directly from the session; if the session no longer holds the `GameID` `.gameSession` referenced, the destination silently pops back to the previous screen in the navigation stack rather than crashing (`.calendar` carries no ID, so this branch does not apply to it) — the entity is never carried inside the route itself.

### AC-06 (US-01, US-05) — domain invariant / structural
**Given** `GameSession`, `DungeonSession`, and `BattleFightViewModel` (the largest battle ViewModel) are being reshaped, with rules delegated to mutators grouped by domain-rule family (e.g. one mutator for the reward-application group, one for the post-DUP-1-collapse inventory-add family) rather than one mutator per method
**When** the reshape is done
**Then** the facades contain no inline domain-rule mutation, and delegation counts as *real* only if (a) the rule lives in a separate injected type — not an extension of the original session/ViewModel type — and (b) that type has its own unit test independent of the facade, with the facade method reduced to a single delegating call; the same type's logic relocated into more extension files of the same type does not satisfy this AC regardless of the resulting line count.

### AC-07 (US-03, US-04) — happy path
**Given** `.gameSession` has been converted to a `GameID` payload and `.calendar` has been converted to a zero-payload case
**When** the Developer simplifies their hand-written equality code and exercises push / pop / re-push
**Then** navigation de-duplication behaves exactly as before for both routes — `.gameSession`'s case-branch compares only `GameID` (matching its prior `Game.id`-based comparison exactly), and `.calendar`'s payload-less case-branch is always equal to itself, matching its prior "any two calendar pushes de-dup" behaviour in practice (all current push call sites always pass the session's own current calendar/day, never a differing one). **Correction (`review`, 2026-07-11):** `AppRoute`'s `Equatable`/`Hashable` conformance stays hand-written for the whole enum — it cannot synthesize while the unconverted battle routes carry `Battle` — so each converted case keeps one minimal branch in that switch (an identity/always-true comparison); "gone" means no per-field/multi-line comparison logic remains for either converted case, not that the switch case itself is removed (the unconverted battle routes keep their full multi-field branches, by design).

### AC-08 (US-07) — happy path / consistency
**Given** the two specific, already-identified documentation issues — a stale doc comment, and the project-docs platform line that no longer matches the package's actual platform declaration
**When** the Developer applies the fix
**Then** the stale comment is removed and the project-docs platform line matches the package's actual platform declaration. Scope is these two named items only — not a repo-wide audit of every code comment (see §3 non-goals).

### AC-09 (US-01) — happy path
**Given** the three near-duplicate inventory-add methods (`addFishToInventory`, `addHerbsToInventory`, `addOresToInventory`) on `GameSession`
**When** the collapse (DUP-1) is complete
**Then** there is one core add path with thin typed shims preserving each method's existing signature at every call site, and existing tests pass unchanged.

## 6. Non-functional requirements

| Aspect | Target | Measurement |
|---|---|---|
| Behaviour neutrality | 100% of existing unit tests pass, unchanged | `xcodebuild test -scheme elf_Kit` |
| Build health | 0 build errors, 0 new warnings | `xcodebuild -scheme elf build` |
| Lint cleanliness | 0 violations, including the new logging rule | `swiftlint --strict` |
| Session / ViewModel size | ≤ 300 LOC is an **advisory** orientation for each reshaped session facade and the split ViewModel — exceeding it while AC-06's delegation criteria are met is a PASS; meeting it without real delegation (AC-06) is a FAIL. AC-06 delegation is the only hard gate. | file line count (advisory only) |
| Navigation de-dup | 0 behaviour change in push / pop / re-push for `.gameSession` and `.calendar` | manual navigation pass + any existing navigation tests |
| Runtime performance | No regression: balance-sweep integration timing within ±5% of the pre-change baseline. **Baseline-capture step (added by clarify):** before the first refactor PR, run `battle_simulation_IntegrationTests` on the pre-change commit and record its duration in the artifact tracking this work (e.g. `tasks.json` or a `design`/`tasks` note) — ±5% is measured against that recorded number. | `battle_simulation_IntegrationTests` duration, vs. the recorded pre-change baseline |

## 6.1 Security / privacy

- **Data classification:** internal — local single-user save files on device; no network surface, no shared/multi-tenant data.
- **Personal data touched:** none — no new fields; no PII anywhere in scope.
- **AuthZ/AuthN impact:** none — offline single-user game, no authentication boundary. The internal access-control mechanism the refactor *preserves* (read-only public state, module-gated mutation — AC-03) is a code-visibility discipline, not a security boundary.
- **Abuse cases:** N/A — an offline local game with no untrusted input, no network, and no multi-tenant surface. The one integrity risk in the wider audit (data loss on a silent save failure) is deferred as E-1 (§3).
- **Security review:** N/A — no network surface, no PII, no auth boundary, no new external input; a purely internal structural/consistency refactor.

## 7. Metrics / KPIs

> Baselines were from the 2026-06-08 review snapshot; this `clarify` pass (2026-07-09) confirmed the three LOC baselines below current by direct file inspection, resolving the two source docs' 556-vs-564 disagreement in favour of 564 — `design` does not need to re-measure those three. The remaining KPIs still carry the review's original "(re-verify)" flag; `design` re-measures those before implementing.

- **`GameSession` facade LOC** (`Packages/elf_Kit/Sources/DataLayer/Sessions/GameSession.swift`) — baseline: 564 (confirmed current), target: ≤ 300 via delegation to mutators (not extension relocation).
- **`DungeonSession` facade LOC** (`Packages/elf_Kit/Sources/DataLayer/Sessions/DungeonSession.swift`) — baseline: 365 (confirmed current), target: ≤ 300 via the same delegation.
- **`BattleFightViewModel` LOC** (`Packages/elf_Kit/Sources/UILayer/BattleFight/BattleFightViewModel.swift`) — baseline: 422 (confirmed current), target: ≤ 300 via the display-extension split pattern.
- **Raw `print` in ViewModels/services-with-a-logger** — baseline: ≥ 6 known sites (re-verify), target: 0, and 0 thereafter (mechanically enforced).
- **Hand-written equality lines on `AppRoute.gameSession` and `AppRoute.calendar`** — baseline: ~72 across the whole `AppRoute` type (re-verify the two-route share specifically), target: each converted case's branch collapses to one identity/always-true comparison line (from a multi-field comparison) — not fully removable, since `AppRoute`'s `Equatable`/`Hashable` conformance stays hand-written overall while the unconverted battle routes carry `Battle` (battle routes retain their full multi-field branches by design). **Corrected (`review`, 2026-07-11)** from an original "target: 0" that assumed synthesized `Hashable` would take over — infeasible while `Battle`-carrying cases stay out of scope; see AC-07.
- **Inline domain-mutation methods on `GameSession`** — baseline: the progression/inventory-add family (incl. the three DUP-1 methods, see AC-09) implemented inline, target: 0 (all delegated to mutators).
- **Existing tests passing** — baseline: ~398 (re-verify), target: ≥ 398 (no regression).

## 8. Open questions

- [ ] What is the exact allow-list for the raw-`print` lint rule (logger implementations + the leaf design-system module with no logger dependency + dev-only tools + diagnostic non-logger files)? Default now: ban only where a logger dependency exists; allow-list those paths. — owner: Vitalii Lytvynov, due: before `sdd:design`
- [ ] Re-baseline the raw-`print` count and the existing-tests count against current code (the three session/ViewModel LOC baselines were already confirmed current by the `clarify` pass — see §7). Default now: `design` re-measures these two remaining counts and updates §7. — owner: Vitalii Lytvynov, due: before `sdd:design`

- [ ] `sad.md` §6 has no sequence flow showing AC-04 invariant #2 (the world-turn roster-reshuffle guard) at runtime — flow jumps from 2 to 4 (self-flagged in `sad.md` §11, confirmed still open by `review` 2026-07-11). The invariant itself is soundly covered by `WorldTurnMutatorTests` (fails if the guard is dropped); this is a documentation-completeness gap only, not a code/test gap. Default now: leave as-is until the next `sad.md` touch on this feature; add the missing `<orchestrator> → WorldTurnMutator` flow (guard-blocked / guard-passed branches) then. — owner: Vitalii Lytvynov, due: next `sad.md` revision for this feature

> Resolved during `clarify` (2026-07-09) and folded into their native sections: the reward/roster-reshuffle invariant test requirement (→ AC-04), the DUP-1 core-add-plus-shims shape (→ AC-09).

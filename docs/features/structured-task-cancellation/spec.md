---
status: Draft
owner: "Vitalii Lytvynov"
reviewers: ["Tech Lead"]
updated_at: "2026-08-06"
feature_size: "XS"
---

# Spec — structured-task-cancellation

> **Glossary:** None — no `CONTEXT.md` exists. The single actor is the **Developer / Maintainer** (the solo dev who uses the dev-only Battle Setup screen to configure ad hoc test battles). No invented `user`/`admin`.
> **Reference module / docs / channels used:** `nextArch/possiblePlans.md` (finding #1, group A of the architecture audit) · `Packages/elf_Kit/Sources/UILayer/Dev/BattleSetup/BattleSetupViewModel.swift` (the affected code) · `Packages/elf_Kit/Sources/DataLayer/Sessions/GameSession.swift` `saveInBackground()` (existing `Task<Void, Never>?`-handle convention, cited as a pattern reference only — its coalescing policy differs deliberately, see §1 ¶3).

## 1. Context

**¶1 — What we're solving, for whom.** Elfy's dev-only Battle Setup screen (`BattleSetupViewModel`) lets the **Developer / Maintainer** configure two heroes — player and bot — for ad hoc battle testing, including picking each hero's weapon and shield. Picking a weapon or shield that needs compatibility validation (two-handed vs. off-hand conflicts) runs that validation inside an ad hoc `Task { }` that is never stored or cancelled. If the Developer changes the same hero's weapon/shield selection again before the first validation resolves, a second concurrent `Task` starts racing the first — and whichever `await` finishes last wins, regardless of which selection was actually made last. The dev tool can then silently show an equipped item that does not match the Developer's last tap — undermining the one thing a testing tool must guarantee: that it reflects exactly what was configured.

**¶2 — Why now.** This is finding #1 (🔴 High severity) in `nextArch/possiblePlans.md`'s Фаза 1 "мелкие важные фиксы" — a real state-race bug, not a style nit, with a fix shape the audit already prescribes. Фаза 1's own stated order ("debt before structure") makes it a natural, low-risk item to close before any of that plan's larger structural tracks begin, and it is small and fully isolated enough to ship on its own.

**¶3 — The committed approach.** Store the in-flight weapon/shield-validation `Task<Void, Never>?` as a property (or properties) on `BattleSetupViewModel`, scoped so that the player's and the bot's validation lifecycles are fully independent (AC-05), and cancel a hero's previous validation `Task` before starting a new one for that hero — cancel-and-replace, matching the audit's own prescribed fix. The exact handle granularity *within* a hero (one handle shared by the weapon and shield slots, or one handle per slot) is a design decision, not fixed here — whichever shape `sdd:design` picks, it must satisfy AC-06: a rapid weapon-then-shield (or shield-then-weapon) selection for the same hero never causes the earlier slot's already-made choice to silently revert to its prior value. This follows the project's existing convention of holding a `Task<Void, Never>?` as a stored handle (see `GameSession.saveInBackground()`), but deliberately does **not** copy that method's coalescing policy (run one more follow-up pass, with fresh data, after the current save finishes): coalescing exists there because every save call is worth persisting once more with whatever state is current at that point. Here a superseded selection's validation result is simply worthless — the new `Task` already validates the new selection — so there is nothing for a follow-up pass to add; cancel-and-replace is the simpler, sufficient policy. Calling `.cancel()` on a non-throwing `Task<Void, Never>` sets its cancelled flag but does **not** interrupt an in-flight `await` that never checks it — `weaponValidator.validateAndResolve` is not required to observe cancellation — so the write into `selectedItems` must be additionally gated at the point of writing (e.g. by comparing the completing `Task` against the hero's currently stored handle) to satisfy AC-03; `.cancel()` alone only prevents a *second* concurrent write, not a stale one.

**¶4 — Traceability & scope caveat.** Grounded in `nextArch/possiblePlans.md` finding #1 and direct inspection of `BattleSetupViewModel.swift:175` (`updateSelectedItems`) on `main` (commit `490e6c8`). A pre-specify scout of the whole repo for the same "unmanaged `Task {}`" pattern found this is the **only** exact match (ad hoc `Task{}` inside a ViewModel/service, mutating `@Observable` state after `await`, never stored/cancelled) — two adjacent issues surfaced nearby and are explicitly **out of scope** here, deferred as separate future findings: (a) `MultiBattleViewModel.runningTask` is dead code — the property and its `cancel()` exist but the property is never assigned, so `cancel()`/`reset()` don't actually cancel anything; (b) three Screens start a `Task { }` from a button action with no `.disabled` guard against a double-tap (`BattleSetupScreen.startBattle()`, `AutoBattleResultScreen`/`MultiBattleResultScreen` "Fight Again") — a different category (View-level navigation/re-run races, not ViewModel state-mutation races).

## 2. Goals

- **Eliminate the state race** — `BattleSetupViewModel`'s equipped weapon/shield selection always reflects the Developer's true last choice for each hero, no matter how quickly they re-select.
- **Make the Task's lifecycle explicit and deterministic** — a hero's stored validation-`Task` handle is replaced only by a newer selection; a completing `Task` never clears or otherwise interferes with a handle that belongs to a newer (still-active) `Task`, and no superseded `Task` can keep running unobserved or write stale state after being replaced.
- **Zero behavior change on the already-correct path** — a single, non-rapid weapon/shield selection resolves exactly as it does today.

## 3. Non-goals

- **No fix for the `MultiBattleViewModel.runningTask` dead code** (finding surfaced during scouting, not group A finding #1) — deferred as a separate future finding, not silently bundled into this fix.
- **No `.disabled`-guard addition on `BattleSetupScreen`/`AutoBattleResultScreen`/`MultiBattleResultScreen`** double-tap paths — a different category of issue (View-level, not ViewModel state mutation), deferred separately.
- **No change to `weaponValidator`'s validation rules** — only to how/when its call is scheduled and superseded, never to what it decides.
- **No change to the debounced `applyAttributes`/`applyEquipment` recompute pipeline** — that flow is already `.task(id:)`-managed by SwiftUI and out of scope for this fix.
- **No repo-wide lint guardrail against unmanaged `Task {}`** — no such guardrail is proposed anywhere in `nextArch/possiblePlans.md` (Group C's items #11–14 cover the `DataLayer`/SwiftUI-import boundary and the `Screens/**` `Default*`-construction pattern, not `Task` lifecycle); if one is wanted later, it is a new, separately-scoped item, not part of this fix.
- **No guard against a non-validating item selection (e.g. boots) being clobbered by a weapon/shield validation `Task` that completes afterward** — `updateSelectedItems`'s validated branch writes back the *entire* `selectedItems` map from a pre-tap snapshot, which can already overwrite an unrelated item picked while validation was in flight; this is a pre-existing behavior, out of scope for this fix (which guards only the `.weapons`/`.shields` race), and is deferred as a separate future finding.
- **No cancellation of an in-flight weapon/shield-validation `Task` when the Battle Setup screen is dismissed** — this fix's cancellation guarantee (Goal 2) covers only a `Task` superseded by a newer selection for the same hero, not one abandoned by leaving the screen; an abandoned `Task` keeps the ViewModel alive until it completes (a resource cost, not an equipped-state correctness issue, since nothing reads the state after dismissal) and is deferred as a separate future finding.

## 4. User stories

### US-01: Trustworthy final selection under rapid re-selection

**As a** Developer / Maintainer
**I want** the dev Battle Setup screen to reflect my actual last weapon/shield choice for a hero, even if I select quickly more than once
**So that** the equipped configuration I see always matches what I actually picked, not a stale validation result that happened to resolve last

### US-02: Regression-safe single selection

**As a** Developer / Maintainer
**I want** a single, non-rapid weapon/shield selection to resolve exactly as it does today
**So that** this fix changes nothing about the already-correct common case

### US-03: A superseded validation never mutates state

**As a** Developer / Maintainer
**I want** a validation `Task` that has been superseded by a newer selection to be barred from writing into the hero's equipped state, even if its underlying async call still completes after being cancelled
**So that** I can trust that only the most recent selection's outcome is ever applied

### US-04: At most one active validation per hero

**As a** Developer / Maintainer
**I want** the system to guarantee at most one in-flight weapon/shield-validation `Task` per hero at any moment
**So that** AC-04's test can prove the invariant holds for this ViewModel — no repo-wide enforcement mechanism (e.g. a reusable cancel-and-replace abstraction) is implied or required by this fix

### US-05: Independent lifecycles for player and bot

**As a** Developer / Maintainer
**I want** the player hero's and the bot hero's validation-`Task` lifecycles to be fully independent
**So that** changing one hero's weapon/shield never cancels or otherwise disturbs the other hero's in-flight validation

## 5. Acceptance criteria

**Term note:** throughout this section, "hero's equipped state" means `HeroConfigurationState.selectedItems` — the raw weapon/shield/etc. picks — not the downstream `applyEquipment`-recomputed values (armor, per-hand damage, attributes). That recompute pipeline is out of scope (§3).

### AC-01 (US-01) — happy path

**Given** a Developer has selected a weapon or shield for a hero on the dev Battle Setup screen and its compatibility validation is in flight
**When** the Developer changes that same hero's weapon or shield selection again before the first validation resolves
**Then** the hero's equipped state ends up reflecting only the second, most-recent selection's validated outcome — the first selection's outcome is never applied, regardless of which validation call happens to finish first

### AC-02 (US-02) — error / invalid input blocked

**Given** a Developer selects a weapon/shield combination the compatibility validation rejects or auto-resolves (e.g. a two-handed weapon conflicting with an already-equipped off-hand item)
**When** that selection is the Developer's final, non-superseded choice for the hero
**Then** the validation's rejection/resolution is still applied to the hero's equipped state exactly as it is today — introducing cancellation for superseded selections does not skip, delay, or partially apply the outcome for a selection that was never superseded

### AC-03 (US-03) — authorization / access denied

**Given** a hero's weapon/shield-validation `Task` has been superseded and cancelled because the Developer made a newer selection for that hero
**When** the superseded `Task`'s validation call completes anyway after cancellation
**Then** the system denies that stale result write access to the hero's equipped state — only the currently active (non-superseded) `Task` for that hero is ever allowed to write the outcome

### AC-04 (US-01, US-04) — domain invariant violation

**Given** the invariant "at most one weapon/shield-validation `Task` is active per hero at a time"
**When** the Developer triggers a new weapon/shield selection for a hero while a previous validation `Task` for that same hero is still running
**Then** the system cancels the previous `Task` for that hero before starting the new one, so the invariant holds at every point in time — it is never observably violated, even under rapid repeated selections. "A new selection" includes re-selecting the same weapon/shield item that is already equipped — matching today's behavior, where every selection call starts a fresh validation regardless of whether the value actually changed

### AC-05 (US-05) — cross-context dependency

**Given** both the player hero and the bot hero have independent, in-flight weapon/shield-validation `Task`s
**When** the Developer selects or edits a weapon/shield for one hero while the other hero's validation `Task` is still running
**Then** the other hero's `Task` continues completely unaffected — cancelling or superseding one hero's validation `Task` never cancels, delays, or otherwise interferes with the other hero's `Task`

### AC-06 (US-01) — cross-slot rapid selection preserves both outcomes

**Given** a Developer has selected a weapon for a hero and its compatibility validation is in flight
**When** the Developer selects a shield for the same hero (or vice versa — a shield selection in flight, then a weapon selection) before the first validation resolves
**Then** the hero's equipped state ends up reflecting both the Developer's final weapon choice and final shield choice — selecting one slot's item never causes the other slot's already-made, not-yet-applied selection to silently revert to its prior value

## 6. Non-functional requirements

| Aspect | Target | Measurement |
|---|---|---|
| Behavior neutrality (single selection) | 100% of existing unit tests pass, unchanged | `xcodebuild test -scheme elf_Kit -destination 'platform=iOS Simulator,name=iPhone 17'` |
| Race safety (rapid re-selection) | 0 out-of-order writes to a hero's equipped state under ≥2 rapid re-selections | new regression test exercising rapid re-selection (AC-01, AC-04), using an injected/controllable fake `weaponValidator` that releases its result in a chosen order — not wall-clock (`Task.sleep`) timing, which cannot guarantee the order deterministically |
| Per-hero isolation | 0 cross-hero interference between player's and bot's validation `Task`s | new unit test (AC-05) |
| Build / lint health | 0 new build warnings, 0 lint violations | `xcodebuild -scheme elf -destination 'platform=iOS Simulator,name=iPhone 17' build`, `swiftlint --quiet` |

## 6.1 Security / privacy

- **Data classification:** internal — dev-only debug screen, local in-memory state only; no network surface, no persisted or shared data.
- **Personal data touched:** none.
- **AuthZ/AuthN impact:** none — offline single-user game, dev-only tooling with no authentication boundary. The internal guard AC-03 describes (only the current, non-superseded `Task` may write a hero's state) is a concurrency-correctness discipline, not a security boundary.
- **Abuse cases:** N/A — a local dev-only screen with no untrusted input, no network, and no multi-tenant surface.
- **Security review:** N/A — no network surface, no PII, no auth boundary, no new external input; a purely internal concurrency-correctness fix.

## 7. Metrics / KPIs

- **Unmanaged (unstored, uncancelled) `Task {}` instances in `BattleSetupViewModel.updateSelectedItems`** — baseline: 1, target: 0.
- **Out-of-order writes to a hero's `selectedItems` under a rapid-reselection regression test** — baseline: N/A (new test), target: 0 out-of-order writes after the fix.
- **Existing `elf_Kit` test-suite pass rate** — baseline: current passing suite (measured live at `sdd:tasks`/`sdd:implement` via the test runner, no fixed count tracked here), target: no regression — 100% of the pre-existing suite still passes.

## 8. Open questions

Deferred by `sdd:review` (see `_review/review-2026-08-06.md`) — non-blocking, not acted on in this pass:

- **AC-04's "per hero" wording vs. the shipped per-slot design.** AC-04 literally reads "at most one weapon/shield-validation Task is active per hero at a time", but the Accepted design (ADR-0001) intentionally keeps up to two concurrent Tasks per hero (one per slot) — required for AC-06 — so the invariant as literally worded does not hold. Either tighten AC-04 to "per slot" or add an explicit override note to `sad.md` §1, so a future reader tests against the invariant the code actually holds. Owner: Vitalii Lytvynov. Due: next spec/SAD touch on this feature.
- **`drainMainActorQueue()`'s 20× `Task.yield()` is a magic-number heuristic wait**, not an explicit synchronization signal (e.g. `await task?.value`) — `BattleSetupViewModelTests.swift`. Verified deterministic in practice today (no further suspension point after the validator call in the resumed continuation), so not a live flake risk — but the margin is empirical, not proven. Owner: Vitalii Lytvynov. Due: revisit only if this suite starts flaking.
- **`FakeWeaponValidator.release(at:)`'s index-shift-on-removal is guarded only by a doc comment**, not the API shape — a future edit that adds/reorders a selection call before releasing could release the wrong pending call. Consider a release-by-identity API (matching on slot/itemId, or an opaque token) if this fake gains more call sites. Owner: Vitalii Lytvynov. Due: before `FakeWeaponValidator` gains a new call site with >2 simultaneous pending calls in one test.

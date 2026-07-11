---
status: Accepted
owner: "Vitalii Lytvynov"
reviewers: []
updated_at: "2026-07-09"
feature_size: "L"
ticket: "architecture-hardening"
---

# 0003 — Convert AppRoute.gameSession and .calendar to ID/zero-payload with destination-side resolution and silent pop-back on mismatch

- **Status:** Accepted
- **Date:** 2026-07-09
- **Deciders:** Vitalii Lytvynov (Architect / Tech Lead / sole developer)

## Context

`AppRoute` (`Packages/elf_iOS/Sources/Navigation/AppRoute.swift`) carries two cases with full domain-model payloads: `.gameSession(Game, playTime: TimeInterval)` and `.calendar(calendar: [GameDay], currentDayNumber: Int)`. Because these payloads aren't cheaply `Hashable`, the enum needs 72 hand-written lines of `Equatable`/`Hashable` across all 8 cases. A direct read of the current code (2026-07-09) shows `.gameSession`'s `view()` case already ignores its own payload — `SessionRouteView { GameDayScreen(session: $0) }` reads `coordinator.gameSession` directly, never touching the route's `Game` or `playTime`. `.calendar`, in contrast, is *not* session-bound today — `CalendarScreen(calendar:, currentDayNumber:)` is constructed straight from the route payload, unlike `.hunt`/`.farm`/`.craft`/`.questList`, which already use the `SessionRouteView { Screen(session: $0) }` precedent. AC-05 requires converting both to carry no full domain model, resolving the entity at the destination, and — for `.gameSession` specifically — silently popping back to the previous screen if the session no longer holds the referenced `GameID` (a real gap: today there is no verification that the pushed route's `Game` matches the coordinator's active session at all).

## Decision drivers

- US-04 + AC-05: routes carry no full domain model — a typed ID where meaningful, no payload where the destination can resolve everything from the session.
- AC-07: navigation de-duplication must behave *exactly* as before after the conversion — `.gameSession`'s synthesized `Hashable` on `GameID` must match its prior `Game.id`-based comparison; `.calendar`'s payload-less case must always equal itself.
- Finding A-2 (`architecture-review.md`): whole domain models inside navigation state is state in the wrong place; the canonical pattern is routes carry IDs, destination screens resolve.
- Established precedent already in the codebase: `.hunt`/`.farm`/`.craft`/`.questList` already resolve their session via `SessionRouteView { Screen(session: $0) }` — this decision extends the same shape to `.gameSession`/`.calendar`, not a new one.
- Behaviour-neutrality — the fallback-on-mismatch path is new code with no prior behaviour to preserve, so its shape needs an explicit choice.

## Considered options

1. **`GameID`/zero-payload with a `SessionRouteView`-style resolution guard and a silent pop-back on mismatch** — `.gameSession(GameID, playTime:)` and `.calendar` (no payload); a small destination-side adapter compares the route's `GameID` against `coordinator.gameSession?.game.id` and, on mismatch, pops the navigation stack back one level instead of presenting stale/wrong state; `.calendar` becomes session-bound via `SessionRouteView { CalendarScreen(session: $0) }`, reading the calendar + current day directly from the session.
2. **Convert the types but skip the mismatch check** — same `GameID`/zero-payload conversion, but the destination keeps blindly reading `coordinator.gameSession` (today's behaviour) without ever comparing it to the route's `GameID`.
3. **Surface a visible error instead of a silent pop-back** — on a `GameID` mismatch, show an error screen/alert rather than popping silently.

## Decision outcome

**Chosen:** Option 1. Option 2 was rejected because it does not satisfy AC-05's literal requirement ("if the session no longer holds the GameID `.gameSession` referenced, the destination silently pops back... rather than crashing") — it would ship the type conversion without the behaviour AC-05 actually asks for. Option 3 was rejected because AC-05 explicitly specifies the *silent* pop-back, not a surfaced error; a mismatch here is not a player-facing failure mode worth interrupting the player over (it can only happen through a stale/leftover navigation-stack entry, e.g. after a session ends and something still holds an old route), and a silent pop matches how the same class of "stale reference in the nav stack" is already handled implicitly elsewhere in the router.

## Consequences

**Positive**
- Removes roughly half of `AppRoute`'s 72 hand-written equality lines (the `.gameSession` and `.calendar` cases collapse to compiler-synthesized `Hashable`).
- `.calendar` gains the same session-bound resolution shape as `.hunt`/`.farm`/`.craft`/`.questList` — one less special case for a future reader to learn.
- The mismatch guard closes a real, previously-unverified gap: today `.gameSession`'s payload could silently diverge from the active session with no detection at all.

**Negative**
- New code path (the mismatch-comparison + pop-back) has no prior behaviour to test against — it needs its own dedicated test, not just "existing tests still pass."
- `.calendar`'s conversion is a bigger code change than `.gameSession`'s (which was already session-bound in practice) — `CalendarScreen`'s init changes shape and its call sites (`GameDayScreen`, `HuntScreen`, `QuestListScreen`, `FarmScreen`, `QuestScreen` — 5 push sites) all move from passing `calendar:`/`currentDayNumber:` to pushing the zero-payload case.

**Neutral**
- The battle routes (`.battleFight`/`.autoBattleResult`/`.multiBattleResult`, carrying `Battle`) keep their hand-written equality — out of scope per spec §3 non-goals (no battle-route ID migration / battle store in this feature).

## Links

- Spec: [[../spec.md]] §4 US-04, AC-05, AC-07
- SAD: [[../sad.md]] §4, §6
- Related ADR: none (independent of the mutator-extraction ADRs)

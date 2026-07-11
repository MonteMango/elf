---
status: Accepted
owner: "Vitalii Lytvynov"
reviewers: []
updated_at: "2026-07-09"
feature_size: "L"
ticket: "architecture-hardening"
---

# 0001 — Keep the surgical refactor inside the existing four modules, no new SPM feature-module

- **Status:** Accepted
- **Date:** 2026-07-09
- **Deciders:** Vitalii Lytvynov (Architect / Tech Lead / sole developer)

## Context

Elfy's codebase already splits into four SPM/Xcode modules — `elf` (app), `elf_iOS` (UI composition), `elf_Kit` (DataLayer + UILayer/ViewModels), `elf_SwiftUI` (design system) — in a strict one-directional graph with no cycles. Two independent audits (`architecture-review.md`, dated 2026-06-08, and a deep-research-backed `architecture-review-summary.md`) diagnosed the real pain as 3–4 god-objects and a couple of flat buckets, not a missing module boundary, and converged on "surgery, not migration." `architecture-hardening` must decide, before any tactical building-block choice, whether the mutator-extraction and navigation-cleanup work happens inside the current four modules or behind a new feature-scoped SPM package (e.g. `CombatKit`).

## Decision drivers

- Behaviour-neutrality quality goal (spec §2 Goals) — the smaller the blast radius of a structural change, the easier it is to prove nothing observable moved.
- No hard deadline / no team (spec §1, SAD §2 Organisational) — there is no build-friction, deploy-cascade, or multi-team-ownership trigger that a new module would relieve.
- Non-goal explicitly stated in spec §3: "No SPM feature-module extraction... both source documents call it premature for a solo pre-ship project with zero build-friction."
- Both `architecture-review.md` §6 (Priority plan, Phase 3) and `architecture-review-summary.md` §4 independently recommend against it and name the real triggers (build-friction, cascading edits, a second developer) as unfired.

## Considered options

1. **Surgical refactor inside the existing four modules** — reshape `GameSession`/`DungeonSession`/`BattleFightViewModel` and `AppRoute` in place, using new folders/types inside `elf_Kit` and `elf_iOS`, no new `Package.swift`.
2. **Extract a `CombatKit` feature-module now** — pull the Combat domain (the largest, most cross-cutting domain per the review) into its own SPM package as part of this feature, establishing feature-module boundaries early.
3. **Introduce a layered sub-package split inside `elf_Kit`** (e.g. separate `DataLayer` and `UILayer` into distinct targets) without going as far as feature modules — a middle ground neither audit recommended.

## Decision outcome

**Chosen:** Option 1 — surgical refactor inside the existing four modules. Both independent audits agree the codebase's pain is concentrated in specific god-objects and flat buckets, not in the module graph itself; none of the standard triggers for a new module (build-friction, cascading edits across a team, a second developer needing an isolated preview target) have fired. Extracting `CombatKit` now (Option 2) would front-load the full tax of modularization — a new `Package.swift`, an explicit public/internal API surface, cross-module test wiring — for near-zero present benefit, and directly contradicts spec §3's non-goal. A sub-package split (Option 3) was not seriously entertained by either source document and adds a second axis of restructuring on top of the mutator work this feature already commits to, raising behaviour-neutrality risk without a named driver.

## Consequences

**Positive**
- Every file touched by this feature stays inside `elf_Kit` / `elf_iOS` — no new build target, no new public API surface to design and defend, no cross-package test wiring.
- Keeps the blast radius of this already-large (L-size) refactor to a single dimension (internal restructuring), not two (restructuring + new module boundary).
- Matches the explicit spec §3 non-goal — no scope drift risk from this decision.

**Negative**
- The god-object surgery still happens inside one large `elf_Kit` target — Swift's whole-module optimization means `elf_Kit` keeps compiling as one unit; no incremental-build isolation is gained from this feature.
- Combat — the domain both audits name as the first real modularization candidate — is left as-is; if a build-friction or team trigger fires later, that migration is still fully ahead, undiscounted by anything done here.

**Neutral**
- This decision is reversible in principle (a later feature can still extract `CombatKit`), but doing so after more code accretes inside `elf_Kit`/`UILayer` will touch more call sites than doing it today — the cost only grows, it does not shrink, while the module stays flat.

## Links

- Spec: [[../spec.md]] §3 Non-goals, §1 ¶3
- SAD: [[../sad.md]] §4
- Related ADR: [[0002-facade-orchestrator-mutator-injection]] (the mutator-extraction pattern this decision scopes)

---
status: Accepted
owner: "Vitalii Lytvynov"
reviewers: []
updated_at: "2026-07-09"
feature_size: "L"
ticket: "architecture-hardening"
---

# 0004 — Enforce the logger-not-print rule with a custom SwiftLint rule and an explicit path allow-list

- **Status:** Accepted
- **Date:** 2026-07-09
- **Deciders:** Vitalii Lytvynov (Architect / Tech Lead / sole developer)

## Context

`architecture-review.md` (finding C-1) found ViewModels bypassing the project's `DebugGameLogger`/`DebugBattleLogger` abstraction via raw `print`. Spec §8 flagged two open questions for `design` to resolve: re-baseline the raw-`print` count, and fix the exact lint allow-list. A direct re-scan of the current repo (2026-07-09) found: **9 confirmed violations** in ViewModels/services that have a logger dependency reachable — `GameSession.swift:487` (1, ironically right next to two lines that *do* use `debugGameLogger`), `CharacterCreationViewModel.swift` (4, lines 201/209/219/222), `GameDayViewModel.swift` (3, lines 93/104/176), `DefaultDungeonRewardCalculator.swift:29` (1) — plus one borderline case, `AppCoordinator.swift:101` (a Coordinator, not literally a ViewModel/service, but DI-composed with a logger reachable). Legitimate non-violations needing an explicit allow-list: the logger implementations themselves (`ConsoleDebugGameLogger.swift`, `ConsoleDebugBattleLogger.swift`), the entire `elf_SwiftUI` package (a leaf design-system module with zero dependencies — cannot inject a logger even if it wanted to), dev-only tooling (`elf_iOS/Screens/Dev/**`, `elf_Kit/UILayer/Dev/**` — including `MultiBattleViewModel.swift`, which intentionally dumps 33 lines of raw balance-sweep stats to console for manual tuning runs), `elf_iOS/Diagnostics/FPSCounter.swift`, and `elf/ElfApp.swift` (prints happen before `DependencyBootstrap.run()` completes — no DI container is wired yet). US-06 requires this to be *mechanical* — the guard must not depend on the developer remembering to check.

## Decision drivers

- US-06 + AC-02: a mechanical lint gate must block a raw `print` where a logger is available and explain the fix in plain language — not rely on code-review vigilance.
- Spec §8 OQ (this feature's own open question, now resolved by design per its "due: before sdd:design" default): the allow-list needs to cover more than logger files alone — a leaf design-system module and dev tools also legitimately print.
- The project already runs `swiftlint` in the build/lint cycle (`CLAUDE.md` Build Commands, `docs/architecture-map.md` `lint_cmd`) — no new tool should be introduced for one rule if the existing one can express it.
- Consistency quality goal (§1) — the guard itself should not require a second CI system to maintain alongside the one already in place.

## Considered options

1. **A custom SwiftLint rule (`custom_rules` in `.swiftlint.yml`)** — a regex match on `print(` scoped by `included`/`excluded` glob paths, so it fires in `elf_Kit`'s `DataLayer/Services/**` and `UILayer/**` (minus `UILayer/Dev/**`) and in `elf_iOS` outside the allow-listed dev/diagnostics/bootstrap paths, with a plain-language `message`.
2. **A CI/pre-commit grep script** — a standalone shell script (not SwiftLint) that greps for `print(` outside the allow-list and fails the build/commit.
3. **Code-review discipline only** — document the rule in `.claude/docs/common-mistakes.md`, rely on manual review to catch regressions (no mechanical gate at all).

## Decision outcome

**Chosen:** Option 1. Option 3 is explicitly ruled out by US-06's requirement that the guard be mechanical, not manual — that is the whole point of this goal. Option 2 (a separate grep script) was rejected because it introduces a second enforcement surface running outside `swiftlint`'s existing invocation; the project already treats `swiftlint --quiet`/`swiftlint --strict` as *the* lint gate (`CLAUDE.md`, spec §6 NFR "Lint cleanliness"), so a second script would either need its own CI wiring or silently only run in a pre-commit hook (invisible to `xcodebuild`/CI runs that only call `swiftlint`). A `custom_rules` regex is also visible in Xcode/the IDE the moment a violation is typed, not only at CI time — closer to "cannot silently return" than a script gated on commit or CI.

## Consequences

**Positive**
- One enforcement surface (`swiftlint`), already wired into the build/lint cycle — no second CI job or hook to maintain.
- Violations surface in the IDE immediately, not just at commit/CI time.
- The allow-list is declarative (`included`/`excluded` in `.swiftlint.yml`) and reviewable in one file, rather than logic embedded in a script.

**Negative**
- A regex rule matches on `print(` textually and is scoped by *path*, not by "does this type actually have a logger dependency" — a new type added inside an allow-listed dev/diagnostic path that later gains a real logger dependency won't be caught until someone re-audits the allow-list; conversely a new non-dev file outside the allow-list is correctly caught from day one.
- SwiftLint `custom_rules` regexes can be defeated by reformatting (e.g. `Swift.print(`) — this is a known, accepted limitation of textual lint rules, not something this ADR's mechanism can close without a full SwiftSyntax-based custom lint plugin (out of scope for this feature's effort budget).

**Neutral**
- The 9 confirmed + 1 borderline current violations are fixed as part of this feature's logging work (§8); the rule going in at the same time is what makes the fix "self-defending" rather than a one-time cleanup that drifts back.

## Links

- Spec: [[../spec.md]] §4 US-02, US-06, AC-02, §8 (the allow-list open question this ADR resolves)
- SAD: [[../sad.md]] §4, §8
- Related ADR: none

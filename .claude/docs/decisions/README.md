# Architecture Decision Records (ADRs)

One markdown file per significant architectural decision. The goal is that future-you (or a
collaborator) can open a file and understand **why** the code looks the way it does, without
archaeological git-digging.

## When to write one

Write an ADR whenever you make a decision that:
- Changes a public protocol or core type's API shape
- Chooses between multiple plausible approaches (not just "the one obvious way")
- Relies on an invariant that isn't obvious from the code
- Reverses a previous decision

Do **not** write one for:
- Pure bug fixes with no design trade-off
- Local refactors within a single file
- Typo/doc fixes

## Format

Copy `_template.md` → `NNNN-short-slug.md` (zero-padded, next free number).

Each ADR has:
- **Status** — `proposed`, `accepted`, `superseded by NNNN`, `deprecated`
- **Context** — what problem / need prompted this
- **Decision** — what we chose, in one paragraph
- **Alternatives considered** — what we rejected and why
- **Consequences** — what becomes easier, what becomes harder, what to watch for

Keep each file short — under 150 lines is the goal. If it's longer, you're probably
documenting implementation rather than decision.

## Index

| # | Title | Status | Date |
|---|-------|--------|------|
| [0001](0001-mainactor-observable-for-game-state.md) | `@MainActor @Observable` for game state (AsyncStream removal) | accepted | 2026-04 |
| [0002](0002-craft-transaction-on-gameservice.md) | `craftItem` lives on `DefaultGameService`, not `CraftService` | accepted | 2026-04-16 |
| [0003](0003-direct-property-write-over-closure-mutation.md) | Direct `player.equipped` writes replace `modifyEquipment` closures | accepted | 2026-04-16 |

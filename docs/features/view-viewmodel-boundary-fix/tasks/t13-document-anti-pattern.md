---
id: T13
title: "Document the View→GameSession bypass as a named anti-pattern in common-mistakes.md"
layer: "docs"
deps: []
acs: []
files_hint: [".claude/docs/common-mistakes.md"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T13 — Document the View→GameSession bypass anti-pattern

## Why

The architecture review (`nextArch/ARCHITECTURE_REVIEW.md` §7) recommends documenting the pattern, not just fixing the point instances — [spec §1 ¶3](../spec.md) ("документированный, проверяемый паттерн, а не только точечно исправленный экземпляр").

## What

Add a named anti-pattern entry to `.claude/docs/common-mistakes.md`: View mutating `GameSession`/`DungeonSession` directly instead of going through its own `@Observable` ViewModel. Include a short wrong-vs-correct code example (View calling `session.foo()` directly vs. View calling `viewModel.foo()`).

## Definition of Done

- [ ] `common-mistakes.md` has a new anti-pattern entry with a short correct-pattern example.

## Notes

No acceptance criteria maps directly to this task — it's the spec §1 self-documentation requirement, not a testable player-facing behavior. Can run independently of the other tasks; natural to do last once the concrete fix pattern (T1–T12) is settled.

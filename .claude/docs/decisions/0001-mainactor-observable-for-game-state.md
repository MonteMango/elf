# 0001 — `@MainActor @Observable` for game state (AsyncStream removal)

- **Status:** accepted
- **Date:** 2026-04 (commit `78c34c6`)

## Context

`DefaultGameService` previously exposed game state via `AsyncStream`/subscription machinery.
Views subscribed to streams to react to changes. Pain points:

- Backpressure and "missed update" bugs — subscribers could lag behind state
- Race conditions on `for await` inside view models
- Subscription lifecycle tied to view lifecycle led to cleanup bugs
- SwiftUI's native reactivity (`@State`, `@Bindable`) was being duplicated manually

iOS 17 `@Observable` macro gives per-property access tracking for free when the state-
holding type is SwiftUI-observable.

## Decision

Make `DefaultGameService` and its nested `PlayerStore` `@MainActor @Observable` final classes.
Remove the `AsyncStream` plumbing entirely. UI state mutations are synchronous main-thread
writes. SwiftUI views observe state via direct property reads inside `body` — per-property
tracking handles invalidation.

## Alternatives considered

- **Keep AsyncStream** — rejected: subscription bugs, no native SwiftUI ergonomics,
  redundant with `@Observable`.
- **Make GameService an `actor`** — rejected: requires `await` at every read site in
  views, poor SwiftUI ergonomics, no real concurrency benefit for a turn-based RPG where
  all mutations originate from user taps (main thread anyway).
- **Keep using `ObservableObject` + `@Published`** — rejected: iOS 17+ project, and
  `@Observable` provides per-property (not per-object) invalidation, avoiding spurious
  re-renders.

## Consequences

**Easier:**
- Views get the property-level granularity they need without manual `@Published` surgery.
- Mutations are just property assignments — no subscription/publisher boilerplate.
- Test setup uses real `DefaultGameService` with in-memory values; no stream mocking.

**Harder:**
- Every read of an `@Observable` property from inside `body` (or a helper that body calls)
  registers tracking. Transient optional-nil states during view unmount can trigger
  re-evaluations on the dying view. See [0003](0003-direct-property-write-over-closure-mutation.md)
  and the `GameDayScreen` crash fix for a concrete case.
- Dependencies on the observable class need `@ObservationIgnored` or they become tracked
  noise.

**Watch for:**
- Unexpected view re-evaluations → check what observable properties `body` reads transitively.
- Crashes during view dismissal when a `@MainActor @Observable` optional is set to nil —
  guard the reading body.
- Partially-migrated code: tests or sibling files still assuming `async` or stream semantics
  (several were found and fixed after the initial migration).

## Related

- [threading-model.md](../threading-model.md) — observation rules and checklist
- [0003](0003-direct-property-write-over-closure-mutation.md) — consequence for mutation API

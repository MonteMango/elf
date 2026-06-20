# WWDC26 Swift Group Lab — Notes & Takeaways

Reference notes from the **WWDC26: Swift Group Lab** (Apple).
Source: <https://www.youtube.com/watch?v=DnMNTWlWzOY>

This is the distilled Q&A. For applying these to Elfy, see the "Relevance to Elfy"
callouts and the companion doc `threading-model.md`.

## Panelists
- **Holly** — Swift team: generics, type inference, compiler diagnostics, concurrency. Language Steering Group + Core Team.
- **Corey** — Swift Server / networking. Structured concurrency, resources, performance.
- **Tony** — Foundation, standard library, packages (algorithms, collections, atomics). Foundation Work Group.
- **Doug** — Swift language team, since day one. Language Steering Group.

## Intro — favorite Swift 6.3 / 6.4 features
| Who | Feature | Summary |
|-----|---------|---------|
| Holly | `@diagnose` attribute + diagnostics improvements | Fine-grained warning control: suppress deprecation in spots, **or opt INTO** off-by-default checks (strict memory safety, strict concurrency) in critical areas. A migration aid. |
| Corey | `async defer` + cancellation shields | Solve the hardest part of structured concurrency — resource cleanup. |
| Tony | New **Subprocess** package | Open source, cross-platform. Plus `Data`/`URL` perf, new `ProgressManager`. |
| Doug | Embedded Swift | Same Swift you write everywhere now runs on bare metal / firmware / tiny devices. |

---

## Q1 — Transfer ownership across isolation domains without a copy
**Holly:**
- **Region-based isolation**: the compiler lets you move non-sendable data between actors **as long as the source actor can no longer access it** after the transfer point. Often inferred automatically.
- **`sending`** keyword — explicitly marks a parameter/return as "non-sendable value transferred out."
- Storing such values currently needs unsafe opt-outs. Active forum pitch **`disconnected`** — a wrapper type that preserves the "disconnected" property through storage so you can transfer it later.

**Takeaway:** `sending` for transfer; region-based isolation is automatic; watch the `disconnected` proposal for storage.

## Q2 — Structured concurrency best practices & pitfalls
**Corey:**
1. **Lean into structure aggressively.** Every escape hatch is trouble.
2. **Avoid unstructured tasks** (`Task { }`, `Task.detached`) at almost all costs — only to send work elsewhere, never in the mainline flow.
3. **Task groups are your friend.** Object lifecycles should fit the lexical scope: create → use in scope → stop using.
4. **`with`-style functions** give nice lexical spelling of that pattern (not required; `deinit`-based cleanup also works).
5. **Write linear async code.** Don't fan out too much. A task is a recipe: A → B → C → D. Parallelize only where needed (fork-join / scatter-gather / fan-out-fan-in).
6. **Cancellation shields** for async cleanup. In a cancelled context most Swift code refuses to run. But if you hold a resource needing async cleanup (flush a half-written file, roll back a DB transaction), wrap the cleanup in a cancellation shield. Pairs with `async defer` — check each `async defer` for awaits that really suspend.

**Tony / Doug — non-sendable types help:**
- Everyone asks "how do I make this Sendable?" — often the right answer is to **make it NON-sendable**, especially ephemeral computation types.
- A non-sendable type can't escape across a concurrency boundary, so within async control flow you reason about it linearly → smaller set of things to think about when you do go concurrent.
- Perf bonus: values you pass across domains should be cheap to pass; intermediate types needn't be.
- `~Sendable` syntax in 6.4 (like `~Copyable`) replaces the old unavailable conformance.
- **Don't overuse `@unchecked Sendable`** in a rush to Swift 6 — it deprives you of compiler guarantees.

**Takeaway:** Structure > escape hatches. No stray `Task{}`. Linear code in task groups, parallelism only where needed. Cancellation shields + `async defer` for cleanup. Rethink the "everything must be Sendable" dogma.

> **Relevance to Elfy:** audit for stray `Task{}` in ViewModels; prefer task groups + `.task{}`. Combat/calculation intermediate types (RNG distributions, builders) are good candidates for staying non-sendable.

## Q3 — Cost of unused conformances (Sendable, Equatable, Hashable, …)
**Doug:**
- **Equatable / Hashable cost** — there's the equality/hashing code, and the conformance is **kept even if unused**, because it's discoverable at runtime via `as? any Equatable`.
- **Sendable is just a tag** — no runtime representation → **zero cost**.

**Corey → Doug:** generic operator overloads (generic over a protocol) **can slow compilation** — they widen the candidate set the type checker must sort through.

**Tony:** only add a conformance if it's **meaningful** (Equatable should mean genuinely equatable).

**Takeaway:** Sendable is free. Equatable/Hashable are not. Don't conform "just in case."

## Q4 — Stopping `@MainActor` contagion in a legacy app
**Holly:**
1. **`@MainActor` by default** for the whole module if almost everything belongs on the main actor; then annotate **only** what offloads.
2. **Start from leaf types**, work outward.
3. **`nonisolated` on individual methods** that don't touch mutable state — then not every use of the type must be on the main actor.
4. **Make state immutable.** Common case: a `static var` that's never mutated (once a computed property, now stored) → make it `let`. Then it needn't be main-actor and stays usable anywhere.

Reference: 2024 code-along "Migrate your app to Swift 6."

**Takeaway:** Don't propagate `@MainActor` blindly. Module-wide default, or leaf-first + `nonisolated` methods + immutability.

> **Relevance to Elfy:** all ViewModels are already `@MainActor`. For DataLayer services, prefer `nonisolated` pure methods + immutable state over blanket main-actor.

## Q5 — Essential modern features for performance
**Tony:** **Profile first** (Instruments, new **flame graph view**). Nate's perf talk (last year). `Span`, `InlineArray`, **unique array** (prototype in Swift Collections).
**Angelica:** new **top functions** filter over the flame graph.
**Corey:** don't forget CS fundamentals — **correct algorithms & big-O** beat API choice.

**Takeaway:** Profile first (flame graph + top functions). Algorithmic complexity over micro-optimizations.

## Q6 — Tear out now-redundant annotations after migration?
**Holly:** **Redundant annotations are fine** and not harmful. Explicitness helps when inference is non-obvious or could change. (E.g., `nonisolated` now allowed on an extension — you *may* remove it from each method, but it's a preference.)
**Tony / Corey / Doug:** an annotation = **documentation of intent** ("this type is intentionally not Sendable"). **Add a short comment explaining *why*** — you'll forget otherwise. Treat your helpers as having an API contract even if they formally don't.

**Takeaway:** Don't strip annotations for cleanliness. Explicitness = docs. Where intent is non-obvious, add a "why" comment.

## Q7 — Why is `UserDefaults` not Sendable when docs say thread-safe?
**Tony:** Foundation's Sendable audit left a **third category**: classes where the superclass is Sendable but a subclass isn't (e.g. `NSString` Sendable, `NSMutableString` not). They chose "not Sendable" rather than mislabel. New `~Sendable` in 6.4 fixes this flexibly: it's **absence** of conformance (not an unavailable conformance), so subclasses decide individually. **The global standard `UserDefaults` will get a Sendable conformance.**

**Takeaway:** "Thread-safe ≠ Sendable" because of class hierarchies. `~Sendable` (6.4) fixes it. Standard UserDefaults becomes Sendable.

## Q8 — Migrate to `borrow`/`mutate` instead of `get`/`set`?
**Doug:** `borrow` = a reference to data held elsewhere; `mutate` = a mutable reference. `get` **produces a new value**; `set` can run arbitrary code. `borrow`/`mutate` are **more efficient** (no copies) **but only when data is actually stored there**; `mutate` requires **exclusive access** (compiler-enforced). Use them where **performance is sensitive and you're handing out already-stored data**; otherwise `get`/`set`.

**Takeaway:** Don't migrate wholesale. `borrow`/`mutate` only for stored data on hot paths.

## Q9 — Which features are for app devs vs systems/embedded? How to keep up?
**Tony:** Swift uses **progressive disclosure** — you needn't learn everything. **Measure first**; non-copyable adds complexity, adopt only when measurements demand it.
**Doug:** when you hit a problem, there's a tool resembling a familiar one but with restrictions for faster code. **unique array resembles array** (array = copy-on-write); swap it in when you see retain/release traffic.
**Corey:** **"Language features aren't collectibles — no prize for collecting them all."** Engineer-hours are finite; if perf is already met, spend time elsewhere. Features are **isolated** — adopt on the hot path only; no whole-project refactor.

**Takeaway:** Don't learn everything. Progressive disclosure. Measure → adopt point-fixes on hot paths.

## Q10 — Slow incremental builds, `swift emit module` taking minutes
**Doug:** type inference / generics / associated types **generally don't** affect overall build perf; occasionally a single expression is slow. Slow **emit module** phase → likely **imported modules**. **Explicit module builds** + the **build timeline** in Xcode reveal where time goes and surface **excess dependencies**. It's like performance-tuning your build. Explicit modules are **on by default** now.

**Takeaway:** Slow emit module → hunt excess dependencies via build timeline + explicit modules, don't blame generics.

## Q11 — What would you design differently in concurrency today? ⭐
**Holly (the headline):**
- The **execution location of nonisolated async functions**. Two proposals: the first made them **always hop to the global concurrent thread pool**; Swift 6.2 made them **stay on the calling context**.
- Why the change: real-world code passed **non-sendable types back and forth** between an actor-isolated context and a nonisolated async function → many data-safety errors (the actor still had access while the async fn ran on the global pool).
- Best default = **run where called**. Offloading to the global pool stays useful but should be an **explicit opt-in**. Wish they'd had this insight from the start.

**Corey / Doug:** the trade-off — more concurrency = more potential parallelism, **but** it pushed types toward Sendable unnaturally. The new model is **easier to start with**, closer to non-concurrent code, with **explicit** points where you introduce concurrency.

**Takeaway:** The big lesson — nonisolated async now runs **on the calling context** (6.2+); offload is an explicit opt-in. Don't make types Sendable needlessly — introduce concurrency explicitly and locally.

> **Relevance to Elfy:** ensure the project builds in Swift 6 language mode so it gets the 6.2 calling-context semantics; review any nonisolated async service methods.

## Q12 — Notable SPM improvements
**Holly:** the big 6.4 change — a **unified build system**. Xcode's SPM and open-source SPM now both use the **Swift Build** package (previously different implementations). Consistency + single maintenance point. Preview in 6.3, default in 6.4. Brings **explicit modules** and better build-graph parallelism to ordinary package builds for free.

**Takeaway:** SPM in Xcode and CLI share one engine (Swift Build) — consistency + more parallelism for free.

## Q13 — Underrated features most devs don't know ⭐ (richest segment)
- **Corey:** `@inlinable` **+** `@inline(never)`. `@inlinable` unlocks more than inlining across modules — **generic specialization** and **effects propagation**. Combined with `@inline(never)` it's great for **generic code with cold paths** (e.g. a slow byte-wise copy fallback): inline the hot path, keep the heavy cold path out of line. `@inline(always)` also stabilized.
- **Holly:** `as` **type annotations** to steer overload resolution. On an ambiguity error, insert `as KnownType` in the relevant sub-expression → fixes overload resolution or yields a more precise error.
- **Corey (meta):** Swift is **open source**, even Darwin-only APIs (language, stdlib, Foundation, networking) are discussed on the forums. iOS devs can influence it without targeting the server.
- **Angelica:** you needn't submit a PR — **asking about a confusing error message** is valuable and improves diagnostics.
- **Corey:** **integer overflow APIs** (`&+` and overflow-reporting methods) — carry the overflow flag through a whole computation, check at the end.
- **Doug:** **keypaths** — reference a property in the abstract without an instance. People build piles of closures unaware keypaths exist; DB drivers live on them.
- **Tony:** **Swiftly** — easy toolchain install to try experimental features; works from Xcode too.

**Takeaway:** Hidden gems — `@inlinable`+`@inline(never)` for hot/cold paths, `as` for overload resolution, keypaths over closures, overflow APIs, Swiftly. Filing diagnostic feedback is a real contribution.

## Q14 — Conditional Equatable/Hashable/Comparable for tuples?
**Holly:** it's an **evolution of parameter packs**. Need to write an extension over a tuple type whose element types are a **parameter pack**, with `where each T: Protocol` (keyword `each`). Need tuple-with-pack syntax + parameterized-extension syntax. Small evolution; an experimental implementation already lives in the compiler repo, nearly there. Eventually lets you add **your own** protocol conformances to tuples too.

**Takeaway:** Conditional tuple conformance is close, gated on parameter packs; experiment already in the compiler.

## Q15 — High-frequency sensor data: background actor → `@Observable` on main, no UI block
**Corey:** depends on what "high frequency" means; if well below UI refresh, maybe nothing to do. If truly high: **minimize context switching**, **accumulate/coalesce**, **debounce**. Consider acceptable **data loss** (a voltmeter needn't render every nanosecond).
**Tony:** **SwiftUI/Observable coalesce updates for free.** Ensure heavy work is async to begin with. **Split the problem**: "what to stream" ≠ "what the user must see."
**Corey:** **swift-async-algorithms** has a `debounce` over AsyncSequence.

**Takeaway:** Don't stream every value to the main actor. Accumulate + debounce (swift-async-algorithms); push only what the user sees; SwiftUI coalesces.

## Q16 — Why is a tuple more expensive than a struct when returned?
**Doug:** handled differently. A **struct** is passed as a **single entity**; a **tuple is "exploded"** — each element passed separately. For a **large** tuple this can be less performant than a big struct. Needs real code + optimizer output to confirm. **File a GitHub issue with a sample.**

**Takeaway:** The compiler explodes tuples into separate values; for large tuples a struct may win.

## Q17 — Favorite quality-of-life / quality-of-code feature
- **Holly (forward-looking):** new **Iterable** protocols — `for-in` directly over a `span`; tied to non-copyable/non-escapable + lifetime/memory safety; expect a wave of new container types.
- **Holly (favorite):** **bidirectional type inference** (how little you write explicitly) + **generics diagnostics**: errors at the **implementation site**, not the use site (unlike monomorphizing languages).
- **Corey:** Swift's tools against **mutable shared state**. Copy-on-write is **a feature you can build yourself**, not a compiler trick; plus the ownership model. The win: **no "spooky action at a distance"** — code is a pure function of inputs/outputs.
- **Tony:** **replacing C with Swift** for safety guarantees — a fluent language without C's sharp edges.
- **Doug:** the **generics system** — a protocol extension method makes writing a generic algorithm as easy as non-generic code; the syntax "melts away."

**Takeaway:** Swift's deep strengths — bidirectional inference, implementation-site diagnostics, ownership/COW against shared mutable state, and generics that don't feel like generics.

---

## Top takeaways (action list)
1. **nonisolated async runs on the calling context** (6.2+); offload to the global pool is an explicit opt-in. — *Q11*
2. **Structured concurrency without escape hatches:** no stray `Task{}`/`Task.detached`; linear code in task groups; parallelism only where needed. — *Q2*
3. **Cancellation shields + `async defer`** for async resource cleanup on cancellation. — *Q2, intro*
4. **Rethink Sendable:** often `~Sendable` is right; avoid `@unchecked Sendable`. — *Q2, Q7*
5. **`@MainActor` without contagion:** module-default OR leaf-first + `nonisolated` methods + immutability. — *Q4*
6. **Profile first** (flame graph + top functions); algorithms over micro-API. — *Q5*
7. **"Features aren't collectibles":** adopt non-copyable / unique array / span point-wise on hot paths, by measurement. — *Q9*
8. **Conformance with care:** Sendable is free; Equatable/Hashable aren't; conform only when meaningful. — *Q3*
9. **Redundant annotations are documentation of intent** (+ a "why" comment). — *Q6*
10. **High-frequency data → main actor:** debounce + accumulate (swift-async-algorithms); SwiftUI coalesces. — *Q15*

## Referenced sessions / resources
- 2024 code-along: "Migrate your app to Swift 6" (`@MainActor` migration).
- Nate's performance + Instruments talk (Span, non-copyable, flame graph).
- Session on explicit build modules (~2 years prior; now default).
- Session on migrating to Swift Testing.
- `swift-async-algorithms` (`debounce`), Swift Collections (unique array prototype), Subprocess package.
- Forums: <https://forums.swift.org> · GitHub: swiftlang org · Toolchains: Swiftly.

<!-- Created by Vitalii Lytvynov -->

---
status: Living
updated_at: "2026-08-08"
---

# Domain Context — elf (Elfy)

<!--
CONTEXT.md is the domain glossary — not a spec and not a scratch pad. NO implementation
detail here (no datastore/broker/framework names, no API contracts) — only domain words
and the boundaries between them. Implementation choices live in the SAD and ADRs; behaviour
lives in spec.md.

Terms get fixed inline, the moment they surface in an interview / spec / review — never
batched «I'll consolidate later». Empty H2 → prune before commit; keep only the sections
that carry real content. ## Glossary is mandatory; the other two are optional.
-->

## Glossary

<!-- One line per term: name · one-sentence canonical definition · one-sentence boundary
     (what it is NOT / the concept it gets confused with). Alphabetical once there are a few. -->
- Developer — the person who writes and maintains Elfy's code (currently its sole author). NOT Player — the Developer acts on the codebase itself, not on an in-game character or session.
- Player — the person playing Elfy, acting through the app's screens on their own local game session. NOT Developer — the Player only ever interacts with the shipped game, never the source code.

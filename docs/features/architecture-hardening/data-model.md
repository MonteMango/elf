---
status: Draft
owner: "Vitalii Lytvynov"
reviewers: ["Tech Lead"]
updated_at: "2026-07-09"
feature_size: "L"
---

# Data model — architecture-hardening

## Convention source

No relational/SQL datastore and no migration tool exist in this repo (`docs/architecture-map.md` frontmatter: `migration_tool: ""`). Persistence is `GameSaveData: Codable` serialized to JSON by the actor `FileGameSaveStorage` (`Packages/elf_Kit/Sources/DataLayer/Persistence/Implementation/FileGameSaveStorage.swift`) into `ApplicationSupport/Elfy/Saves/*.json`. Per `CLAUDE.md` §Save/Persistence Policy and the architecture map's Migrations row, save-format migrations are explicitly **not supported** pre-ship — the shape of `Game`/`GameSaveData` may change freely and old saves are wiped, not migrated.

## Schema-change assessment

This feature is a strictly **behaviour-neutral** structural refactor (spec.md §2 Goals, §3 Non-goals; sad.md §1 QG-3 "Behaviour neutrality"). It:

- reshapes `GameSession`/`DungeonSession`/`BattleFightViewModel` from god-objects into orchestrators over DI-injected mutators (ADR-0002) — an **internal code-organization** change, not a data-shape change;
- converts two `AppRoute` navigation-route payloads (ADR-0003) — in-memory `NavigationStack` state, never persisted to a save file;
- routes logging through the existing logger dependency (ADR-0004) — no data touched;
- collapses three duplicate inventory-add methods into one core path with typed shims (AC-09) — same call-site signatures, same resulting inventory state.

None of these introduce a new persisted entity, a new field on an existing `*SaveData` type, or a change to any existing field's type/optionality. `sad.md` §5 (Building block view) lists only new **Swift service types** under `DataLayer/Services/` and reshaped orchestrators — no new file under `DataLayer/Persistence/Model/`. `sad.md` §7 (Deployment view) confirms no new datastore. §8 (Crosscutting concepts) confirms the ID strategy (`TypedID<Tag>`) and error-handling convention are unchanged, only `AppRoute.gameSession`'s in-memory payload type changes (`Game` → `GameID`), which is navigation state, not save-file schema.

**Conclusion: no schema change.** Per this skill's Definition of Done, a run that finds no schema change legitimately produces a minimal `data-model.md` (this file) documenting the existing entities the feature touches, with **zero** staged migrations — a valid outcome, not a failure. `api` would also have accepted the fast-lane skip (no contract change) for the same reason.

## Existing entities touched (unchanged shape)

| Entity | File | How this feature touches it | Shape change |
|---|---|---|---|
| `GameSaveData` | `Persistence/Model/GameSaveData.swift` | Written by `GameSession.saveInBackground()`, which continues to call the same save path after the facade→orchestrator reshape | None |
| `InventorySaveData` | `Persistence/Model/InventorySaveData.swift` | Populated by the collapsed `InventoryAddMutator` (AC-09) instead of three separate `GameSession` methods; same resulting fields/values | None |
| `Game` (in-memory, not a `*SaveData` type) | `Packages/elf_Kit/Sources/DataLayer/Model/...` | Resolved by `GameID` at the navigation destination instead of being carried in `AppRoute.gameSession`'s payload (ADR-0003) | None (navigation state only, not persisted) |

No other `*SaveData` type (`ElfSaveData`, `EquippedItemsSaveData`, `WeaponSaveData`, `DungeonRunSaveData`, etc.) is referenced by this feature's scope.

## Migrations

None. No `.up.sql`/`.down.sql` pair is staged under `docs/features/architecture-hardening/migrations/` — there is no schema change and no migration tool in this repo (see Convention source above).

## Test fixtures

No new persistence fixtures. The 12 new mutator types (ADR-0002) get their own unit tests per AC-06's delegation rule, using the repo's existing in-memory test-builder patterns for `GameSession`/`DungeonSession` state — not save-file fixtures, since no save shape changes.

## Drift check

No drift: the existing domain layer's `*SaveData` types already match the persisted JSON shape (per `docs/architecture-map.md` Datastores section), and this feature does not modify that shape.

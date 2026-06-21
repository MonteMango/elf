# Model Organization

How domain types are grouped under `Packages/elf_Kit/Sources/DataLayer/Model/`,
and **where a new type belongs**. This is the taxonomy/folder guide; for the
mechanics of two related areas see:

> **One exception to "under `Model/`":** the on-disk `*SaveData` DTOs no longer
> live in `Model/Persistence/`. They moved to their own top-level `DataLayer`
> group, **`Persistence/Model/`**, co-located with the storage that reads/writes
> them (`GameSaveStorage` / `FileGameSaveStorage`). They are still models by
> nature, so this guide still owns the "where does a `*SaveData` go" decision —
> the path is just `DataLayer/Persistence/Model/`, not `DataLayer/Model/Persistence/`.

- Persistence / `*SaveData` round-trip → `persistence-patterns.md`
- `TypedID`, phantom types, sum/product modelling → `type-driven-design.md`

> All game **models are value/identity types only** — no business logic, no
> services, no DI. They live in `elf_Kit`'s `DataLayer/Model`. Logic that
> operates on them lives in services / sessions / ViewModels (see
> `project-architecture.md` → Business Logic Rules).

---

## The 8 groups

Every model file lives in exactly one group. The split is by **lifecycle and
role**, not by feature. Seven groups sit under `DataLayer/Model/`; the eighth,
`Persistence/`, lives at `DataLayer/Persistence/Model/` (see note above).

| Group | Role | Mutability | `Codable`? | ID / naming |
|-------|------|-----------|-----------|-------------|
| `Model/Shared/` | Cross-cutting primitives | — | mixed | `TypedID`, `BodyPart` |
| `Model/ValueTypes/` | Domain primitives with invariants | immutable | yes (leaf fields) | `Attribute`, `HitPoints`, … |
| `Model/Catalog/` | Static reference data decoded from JSON | immutable | `Decodable`/`Codable` | `*` + `*ID` + `*Data` wrapper |
| `Model/OwnedItems/` | Player-owned instances of catalog items | identity | no (via SaveData) | `Elf*Item`, `OwnedItemID` |
| `Model/RuntimeDomain/` | Live, evolving game state | mutable | **mostly no** (via SaveData) | `*ID` |
| `Model/Combat/` | Battle mechanics, snapshots, results | mixed | mixed | `*Snapshot`, `Applied*` |
| `Persistence/Model/` | On-disk DTOs of runtime state | immutable | **yes** | `*SaveData` |
| `Model/Dev/` | Simulation/statistics for balancing | immutable | no | `*Result`, `*Statistics` |

---

### `Shared/` — cross-cutting primitives

Infrastructure used by every other group.

- `TypedID.swift` — `TypedID<Tag: IDType>`, the phantom-typed UUID wrapper behind
  every `*ID`. See `type-driven-design.md` → Phantom Types.
- `BodyPart.swift` — `enum BodyPart { head, body, leftHand, rightHand, legs }`,
  used by armor/damage/combat targeting.

Put a type here only if it's genuinely domain-agnostic and used across ≥3 groups.

### `ValueTypes/` — domain primitives with invariants

Small wrappers that make an invalid value unrepresentable. Immutable, `Codable`
so they can serialize as leaf fields, often `Comparable`/`AdditiveArithmetic`.

`Attribute` (clamped ≥ 0 `Int16`), `ActionPoints` (`0 ≤ current ≤ maximum`),
`HitPoints` (current may go ≤ 0 for overkill), `ItemTier` (rarity enum),
`CharacterName`, `DamageRange`.

> A "value with rules" → here. A "thing with identity" → `RuntimeDomain`/`OwnedItems`.

### `Catalog/` — static reference data (JSON)

Immutable definitions decoded once at startup and served by repositories
(`MonsterRepository`, `DungeonRepository`, …). These never mutate during play.

Subfolders mirror content domains: `Monster/`, `Dungeon/`, `Fish/`, `Herb/`,
`Ore/`, `Material/`, `Quest/`, `Recipe/`, `ItemDefinitions/`.

```swift
// Catalog/Monster/Monster.swift
public struct Monster: Codable, Sendable, Identifiable, Hashable {
    public let id: MonsterID            // all `let`
    public let hitPoints: Int
    public let rightAttack: AttackProfile
    public let drops: MonsterDrops
}
```

Naming: singular type (`Monster`), `MonsterID = TypedID<MonsterIDType>`, and a
top-level JSON envelope `MonstersData` / `DungeonsData`. `Item` is a
`Decodable` protocol with concrete `WeaponItem` / `DefenseItem` / … definitions.

### `OwnedItems/` — player-owned instances

The bridge between a shared catalog `Item` and a player's inventory. Each is a
`final class` (identity semantics) carrying an `OwnedItemID` distinct from the
catalog `ItemID`, plus per-instance state (e.g. `enchantLevel`). Not `Codable`
— they round-trip through `*SaveData`.

```swift
// OwnedItems/ElfWeaponItem.swift
public final class ElfWeaponItem: ElfItem, Hashable, Sendable {
    public let id: OwnedItemID          // instance identity
    public let item: Item               // → catalog definition
    public let enchantLevel: Int
}
```

`ElfWeaponItem`, `ElfOneHandedWeaponItem`, `ElfTwoHandedWeaponItem`,
`ElfShieldItem`, `ElfDefenseItem`, `ElfRobeItem`, `ElfJewelryItem`, the `ElfItem`
protocol, and `OwnedItemID`.

> Catalog `Item` = the blueprint (one, shared). `Elf*Item` = a copy a player owns
> (many, each with its own `OwnedItemID`).

### `RuntimeDomain/` — live game state

The mutable heart of a session: things that change as you play. Value types
(`struct`) with `var` stored properties, `Sendable`/`Equatable`, derived data
as computed properties.

Subfolders: `Game/`, `House/`, `Elf/`, `Equipment/`, `Inventory/`, `GameDay/`,
`Character/`, `Craft/`, `World/`, `Activities/` (Fishing, Mining, Foraging,
Hunt, …), and `Dungeon/`.

```swift
// RuntimeDomain/Elf/ElfInfo.swift
public struct ElfInfo: Sendable, Equatable, Identifiable {
    public let id: ElfID
    public var currentExp: Int
    public var equipped: EquippedItems
    public var inventory: ElfInventory
    public var globalBuffs: [AppliedBuff]
    public var maxHP: Int16 { totalAttributes.hitPoints.intValue }   // computed
}
```

`Codable` rule of thumb: the **large aggregates** (`Game`, `ElfInfo`, `House`,
`ElfInventory`, `EquippedItems`) are deliberately **not** `Codable` — they
persist through the `*SaveData` layer so catalog references stay as IDs. **Small
leaf value types** here (`InventoryMaterial`, `MaterialRef`, `GatherableItem`, …)
may be `Codable` for convenience.

> **`ElfInfo` carries no runtime HP/MP.** Only the computed `maxHP`/`maxMP` caps
> exist; live hit/mana points during a dungeon run live on `DungeonElfVitals`
> (see the Catalog-vs-Runtime example below).

### `Combat/` — battle mechanics

Combat-specific state and results, separate from both catalog and persisted
domain. Subfolders: `Combat/`, `Battle/`, `Buff/`, `Crit/`, `Damage/`, `Dodge/`,
`Drop/`.

- `CombatantSnapshot` — a unified, battle-scoped copy of an elf or monster;
  `currentHP/MP/EP` mutate during the fight and are **discarded** at battle end
  (the `*Snapshot` suffix signals "throwaway battle copy").
- `Battle`, `BattleRound`, `BattleOutcome`, `RoundOutcome` — a fight and its
  results.
- `Buff` (catalog-like definition) vs `AppliedBuff` (an instance on an elf or
  snapshot, FK `buffId: BuffID`) — the `Applied*` prefix marks the instance form.
- `Crit`/`Damage`/`Dodge` — `*CalculationResult` / `*Distribution` outputs of
  combat math.

### `Persistence/Model/` — on-disk DTOs

`Codable` mirrors of runtime state, with a **bidirectional** round-trip. Lives in
the top-level `DataLayer/Persistence/` group (next to `GameSaveStorage` /
`FileGameSaveStorage`), not under `Model/`. See `persistence-patterns.md` for the
full flow and the ID-Reference pattern.

```swift
public struct ElfSaveData: Codable, Sendable {
    public init(from elf: ElfInfo) { … }                       // freeze
    public func toElfInfo(itemsRepository:, inventoryService:) throws -> ElfInfo  // thaw
}
```

Naming: `*SaveData`. Freezing is `init(from: RuntimeType)`; thawing is
`toRuntimeType(...)` and needs repositories to resolve `ItemID` → catalog `Item`.
`GameSaveData` is the root.

### `Dev/` — simulation & statistics

Non-shipping types for balancing: `BattleResult`, `MultiBattleResult`,
`AutoBattleRoundResult`, `BattleStatistics`, `AggregatedBattleStatistics`. Not
persisted, not in the player-facing flow.

---

## How the layers connect

The item lifecycle threads through four groups — a good mental model for the
whole system:

```
Catalog/ItemDefinitions/WeaponItem      (blueprint, ItemID, from JSON)
        │ wrapped by
        ▼
OwnedItems/ElfWeaponItem                (instance, OwnedItemID + enchantLevel)
        │ stored in
        ▼
RuntimeDomain/Inventory/ElfInventory    (live collection on ElfInfo)
        │ frozen as / thawed from
        ▼
Persistence/Model/WeaponSaveData        (Codable: { id, itemId, enchantLevel })
```

Persistence stores only the `itemId` (an `ItemID`), never the catalog payload;
on load it re-resolves through the repository. That's the **ID-Reference
pattern** — details in `persistence-patterns.md`.

### Catalog vs RuntimeDomain for the *same* domain

`Dungeon/` exists in both groups, which makes the split concrete:

- `Catalog/Dungeon/` — the static map: `Dungeon`, `DungeonRoom`,
  `DungeonRoomKind`, `MonsterRef`. Decoded from JSON, never mutated.
- `RuntimeDomain/Dungeon/` — the live run: `DungeonElfVitals` (each elf's
  current HP/MP during the run). Mutates per battle, discarded when the run ends.

> Static layout → `Catalog`. State that changes as you play → `RuntimeDomain`.

---

## Decision guide — where does my new type go?

1. **Decoded from a JSON catalog, never changes at runtime?** → `Catalog/<Domain>/`
   (+ a `*ID` and, if it's a file root, a `*Data` envelope).
2. **A small value with a rule/invariant** (range, clamp, non-empty)? →
   `ValueTypes/`.
3. **A player-owned instance of a catalog item** (has its own identity/enchant)?
   → `OwnedItems/`.
4. **Mutable state that evolves during a session?** → `RuntimeDomain/<Domain>/`.
5. **Only meaningful inside a battle** (snapshot, round, buff instance, calc
   result)? → `Combat/<Subdomain>/`.
6. **A `Codable` shape that exists only to save/load** a runtime type? →
   `Persistence/Model/` as `*SaveData` (add `init(from:)` + `toX(...)`).
7. **Simulation/stat output for balancing?** → `Dev/`.
8. **Genuinely domain-agnostic, used everywhere?** → `Shared/`.

Conventions to keep:

- IDs are always `typealias FooID = TypedID<FooIDType>` — never a raw `UUID`/`String`.
- Suffixes carry meaning: `*SaveData` = on-disk DTO, `*Snapshot` = throwaway
  battle copy, `*Ref` = ID-only reference, `*Data` = JSON file envelope,
  `Applied*` = instance of a catalog definition.
- Models stay logic-free. If your "model" needs a service or `@Dependency`, the
  logic belongs in a service/session/ViewModel, not the model file.

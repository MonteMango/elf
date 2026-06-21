# Persistence Patterns

## Overview

Game state is persisted using JSON files with atomic writes and backup strategy.

**Technology:** JSON files (not UserDefaults, not CoreData)
**Location:** `~/Library/Application Support/Elfy/Saves/`

```
Saves/
├── slot_default.json      # Main save file
├── slot_default.backup    # Backup of previous save
└── slots.json             # Index of all save slots metadata
```

---

## Architecture

> **Naming note (current code):** the facade is **`GameSession`** (not
> `GameService`) and the storage protocol is **`GameSaveStorage`** with
> **`FileGameSaveStorage`** as the file implementation (not `GameRepository`/
> `FileGameRepository`). Older diagrams/examples below still use the legacy
> names — read them as `GameSession` / `GameSaveStorage`. Persistence is driven
> through `GameSession.save()` (async) and `GameSession.saveInBackground()`
> (fire-and-forget); `GameSaveStorage.load(slotId:)` returns a **`LoadedSave`**
> `{ game, dungeonRun? }`.

```
┌─────────────────────────────────────────────────────────┐
│                     UI Layer                            │
│  ElfApp, GameDayViewModel, MainMenuViewModel            │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                   GameService                           │
│  Manages game session, triggers save/load               │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                  GameRepository                         │
│  Protocol: save(), load(), listSlots(), deleteSlot()    │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                FileGameRepository                       │
│  JSON encoding/decoding, atomic writes, backup          │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                   File System                           │
│  Application Support/Elfy/Saves/*.json                  │
└─────────────────────────────────────────────────────────┘
```

---

## Save Flow

```
1. UI Event (day ends, app backgrounds, battle ends)
   │
2. ViewModel calls gameService.saveGame()
   │
3. GameService calls gameRepository.save(game, slotId, playTime)
   │
4. FileGameRepository:
   ├── Convert Game → GameSave (DTO)
   ├── JSONEncoder.encode()
   ├── Write to temp file (.tmp)
   ├── Create backup of existing file (.backup)
   ├── Move temp file to final location
   └── Update slots index (slots.json)
   │
5. JSON file saved to Application Support
```

### Code Example
```swift
// GameDayViewModel
public func advanceToNextDay() async {
    gameService.advanceToNextDay()
    try? await gameService.saveGame()
}

// DefaultGameService
public func saveGame() async throws {
    guard let repository = gameRepository else { return }
    try await repository.save(game, slotId: slotId, playTime: playTime)
}
```

---

## Load Flow

```
1. MainMenuViewModel.loadGame()
   │
2. gameRepository.loadDefault()
   │
3. FileGameRepository:
   ├── Read JSON file (try backup if main fails)
   ├── JSONDecoder.decode() → GameSave
   ├── Check version, migrate if needed
   └── Convert GameSave → Game (using ItemsRepository)
   │
4. Game object restored
   │
5. Container creates GameService with loaded game
   │
6. GameDayViewModel receives GameService
```

### Code Example
```swift
// MainMenuViewModel
public func loadGame() async {
    do {
        loadedPlayTime = await gameRepository.getPlayTime(slotId: SaveSlotInfo.defaultSlotId)
        loadedGame = try await gameRepository.loadDefault()
    } catch let error as GameSaveError {
        loadError = error.errorDescription
    }
}
```

---

## Data Models

```
GameSave (DTO wrapper)
├── version: Int (current = 1)
├── savedAt: Date
├── appVersion: String
├── playTime: TimeInterval
├── data: GameSaveData
│   ├── gameId: UUID
│   ├── houses: [HouseSaveData]
│   │   └── members: [ElfSaveData]
│   │       ├── attributes, equipment slots
│   │       └── inventory: InventorySaveData
│   ├── gameState: GameStateSaveData
│   ├── playerHouseIndex: Int
│   └── playerMemberIndex: Int
└── dungeonRun: DungeonRunSaveData?   (in-progress run; nil if not in a dungeon)
    ├── dungeonId, allyIds, elfLocations, roomVitals, clearedRoomIds
    └── pendingRewards: DungeonRunRewardsSaveData   (banked XP/drops, id-refs)
        └── experience, materials, weapons[WeaponSaveData], armor[DefenseSaveData]

SaveSlotInfo (metadata for quick access)
├── slotId, savedAt, playTime
├── currentDay, playerName, playerLevel
└── houseName
```

---

## ID-Reference Pattern (IMPORTANT)

**Rule: Data from `elf/Resources/*.json` files must NEVER be encoded in save files.**

### Resource Files
```
elf/Resources/
├── HeroItems.json    → ItemsRepository      (weapons, armor, jewelry)
├── Materials.json    → MaterialRepository   (crafting materials)
└── Monsters.json     → MonsterRepository    (enemy definitions)
```

### Why?
Encoding full structures from Resources would:
- Bloat save files (items have many properties)
- Break saves when item stats are updated
- Duplicate static data unnecessarily

### The Pattern
**Save:** Store only `itemId` (reference) + instance-specific data
**Load:** Use Repository to reconstruct full object from ID

### Save Flow
```
Game Object                    SaveData                      JSON File
─────────────────────────────────────────────────────────────────────────
ElfWeaponItem {               WeaponSaveData {              {
  id: UUID,           →         id: UUID,            →        "id": "...",
  item: WeaponItem,             itemId: UUID,                 "itemId": "...",
  enchantLevel: Int             enchantLevel: Int             "enchantLevel": 0
}                             }                             }

(Full item data)              (Only IDs!)                   (Minimal JSON)
```

### Load Flow
```
JSON File                     SaveData                      Game Object
─────────────────────────────────────────────────────────────────────────
{                             WeaponSaveData {              ElfWeaponItem {
  "id": "...",        →         id: UUID,            →        id: UUID,
  "itemId": "...",              itemId: UUID,                 item: WeaponItem, ← from Repository
  "enchantLevel": 0             enchantLevel: Int             enchantLevel: Int
}                             }                             }

                              ↓
                    repository.getHeroItem(itemId)
                              ↓
                    Returns full WeaponItem from HeroItems.json
```

### Code Example
```swift
// WeaponSaveData.swift
public struct WeaponSaveData: Codable {
    public let id: UUID        // Instance ID
    public let itemId: UUID    // Reference to HeroItems.json
    public let enchantLevel: Int

    // Save: Extract only IDs
    public init(from weapon: ElfWeaponItem) {
        self.id = weapon.id
        self.itemId = weapon.item.id  // Only store the ID!
        self.enchantLevel = weapon.enchantLevel
    }

    // Load: Reconstruct using Repository
    public func toElfWeaponItem(using repository: ItemsRepository) -> ElfWeaponItem? {
        guard let item = repository.getHeroItem(itemId) as? WeaponItem else {
            return nil  // Item not found - save corrupted or item removed
        }
        return ElfWeaponItem(id: id, item: item, enchantLevel: enchantLevel)
    }
}
```

### What Each SaveData Stores

| SaveData Type | Stores | Does NOT Store |
|---------------|--------|----------------|
| WeaponSaveData | id, itemId, enchantLevel | title, damage, stats, abilities |
| ShieldSaveData | id, itemId | title, defense, blockPoints |
| DefenseSaveData | id, itemId | title, armor value, stats |
| RobeSaveData | id, itemId | title, stats, protection |
| JewelrySaveData | id, itemId | title, stats, effects |
| MaterialSaveData | id, quantity | title, description, rarity |

### Benefits
1. **Small save files** — Only UUIDs stored, not full item data
2. **Update-safe** — Can change item stats without breaking saves
3. **Single source of truth** — Item data only in Resources/*.json
4. **Fast lookup** — Repository uses O(1) dictionary lookup

### Error Handling
```swift
// If item not found in Repository during load
throw GameSaveError.missingItemData(itemId: saveData.itemId, itemType: "weapon")
```

This error means:
- Item was removed from HeroItems.json, OR
- Save file is corrupted, OR
- Wrong version of Resources loaded

---

## Dungeon Run Save & Restore

An in-progress dungeon run is persisted **alongside** the game so quitting
mid-dungeon and tapping **Continue** resumes in the same room with the same
squad state. `Game` stays pure — the run is a sibling field on the save.

**Save shape**
- `DungeonRunSaveData` (`Persistence/Model`, Codable, ID-reference): `dungeonId`,
  `allyIds`, `elfLocations: [ElfID: DungeonRoomID]`, `roomVitals: [ElfID: DungeonElfVitals]`,
  `clearedRoomIds: [DungeonRoomID]` (sorted for deterministic output),
  `pendingRewards: DungeonRunRewardsSaveData` (the run's banked XP/drops). No catalog
  payload — dungeon/rooms/elves/items resolve from repositories on load.
- `DungeonRunRewardsSaveData` (`Persistence/Model`, Codable, ID-reference): the
  on-disk form of the runtime `DungeonRunRewards` ledger — `experience`,
  `materials`, `weapons: [WeaponSaveData]`, `armor: [DefenseSaveData]`. The live
  ledger holds **resolved** `ElfWeaponItem`/`ElfDefenseItem`; `init(from:)` snapshots
  to ids and `toRewards(using: ItemsRepository)` resolves back on restore.
- `GameSave.dungeonRun: DungeonRunSaveData?` — optional, so out-of-dungeon and
  older saves decode `nil`.
- `LoadedSave { game: Game, dungeonRun: DungeonRunSaveData? }` — the load result.

**Save** — `GameSession.save()` passes `dungeonSession?.resumableSaveData()`,
which returns the snapshot **only when the run is resumable** (`isInRun &&
!heroIsDowned`). A briefing (not yet entered) or a downed-hero run persists
`nil`, so a background save in those states can't resume into a broken/over run.

**Run end** — the reward ledger is flushed into the player and the session
released, so the next save writes `dungeonRun = nil` (a finished run is never
resumed). Three intent-named exits:
- **Finish** (`DungeonScreen`) → `GameSession.finishDungeonRun()` — flush banked
  XP/drops into the player, then release.
- **Hero death** (`BattleFightRouteView` at conclusion) → `bankDungeonRewardsOnDeath()`
  flushes the ledger into the always-saved player state *before* any downed-state
  save erases it; the result screen's `finishDungeonRun()` then just releases
  (ledger already empty — idempotent).
- **Invalid resume discard** (`AppCoordinator`, dungeon/room no longer resolves) →
  `discardDungeonRun()` — release **without** flushing (the run never legitimately
  ran). The "discard" name is deliberate so throwing away rewards is explicit.

**Restore** — on Continue, `AppCoordinator.startGame(game, playTime:, dungeonRun:)`
recreates the `DungeonSession` (`startDungeonSession` + `restore(from:)`) and
**discards it** (→ Game Day) if `isResumeStateValid()` is false (dungeon, hero
room, or a cleared room no longer resolves). `MainMenuScreen` then pushes
`.gameSession` and, if `coordinator.resumeRoute != nil`, `.dungeon(...)` —
landing the player in the room. `AppRoute` stays **non-Codable**: the resume
pointer is simply `dungeonRun != nil`, and the stack is rebuilt programmatically
(no `NavigationPath` serialization).

**Catalog drift on the rewards ledger (known limitation).** Banked weapon/armor
drops persist as id-references, so the *same instance* the room overlay showed is
the one the player receives — guaranteed **within a session** (the live ledger
holds resolved items; flush hands them over directly). The only gap is a *resumed*
run whose catalog changed between save and resume: `DungeonRunRewardsSaveData.toRewards`
drops an item whose `itemId` no longer resolves (logged in DEBUG). This is the
**same behavior as every `*SaveData.toRuntimeType(using:)` in the project** (id-refs
can't outlive a deleted catalog id) and is out of scope under the early-dev save
policy (saves needn't survive across builds). If/when save-versioning lands, this
is solved globally by a catalog-migration strategy — not per-feature here.

## Auto-save Triggers

| Trigger | Location | When |
|---------|----------|------|
| Day change | `GameDayStateViewModel` / `GameSession.advanceToNextDay()` | After the world turn + day advance |
| App background | `AppCoordinator.saveIfNeeded()` (scenePhase) | App goes to background/inactive |
| After hunt battle | `GameSession.concludeHuntBattle()` → `saveInBackground()` | XP/drops applied, then background save |
| Dungeon step | `DungeonViewModel.persist()` / `BattleFightRouteView` / Finish / death → `GameSession.saveInBackground()` | Enter room, room cleared, room transition, run end |
| New game | `ElfGameInitializationService` | After creating new game |

`GameSession.saveInBackground()` is the single fire-and-forget save home; all
battle/dungeon checkpoints route through it. It **coalesces**: at most one save
runs at a time (`saveInFlight`/`saveAgain`), and requests arriving mid-save
collapse into a single follow-up pass that captures the latest state — so rapid
checkpoints can't pile up independent Tasks contending on the storage actor, and
the newest snapshot always wins.

---

## Error Handling

```swift
public enum GameSaveError: Error {
    case checksumMismatch
    case unsupportedVersion(Int)
    case migrationFailed(from: Int, to: Int)
    case corruptedData
    case slotNotFound(String)
    case fileWriteFailed(Error)
    case fileReadFailed(Error)
    case encodingFailed(Error)
    case decodingFailed(Error)
    case missingItemData(itemId: UUID, itemType: String)
}
```

**Fallback Strategy:**
1. Try to load main file (slot_default.json)
2. If fails → try backup file (slot_default.backup)
3. If both fail → throw corruptedData error

---

## Versioning & Migration

```swift
// GameSave
public static let currentVersion = 1

// FileGameRepository
if gameSave.version < GameSave.currentVersion {
    return try migrate(data: data, fromVersion: gameSave.version)
}

private func migrate(data: Data, fromVersion: Int) throws -> Game {
    switch fromVersion {
    case 1:
        // Current version, no migration needed
        let gameSave = try decoder.decode(GameSave.self, from: data)
        return try gameSave.toGame(itemsRepository: itemsRepository)
    default:
        throw GameSaveError.unsupportedVersion(fromVersion)
    }
}
```

---

## Key Files

| File | Purpose |
|------|---------|
| `Persistence/GameSaveStorage.swift` | Storage protocol (+ `loadDefault`, no-dungeon `save` overload) |
| `Persistence/Implementation/FileGameSaveStorage.swift` | JSON file implementation (atomic + backup) |
| `Sessions/GameSession.swift` | Session facade: `save()`, coalesced `saveInBackground()`, `concludeHuntBattle()`, `finishDungeonRun()` / `bankDungeonRewardsOnDeath()` / `discardDungeonRun()` |
| `Sessions/DungeonSession.swift` | `makeSaveData()` / `resumableSaveData()` / `restore(from:)` / `isResumeStateValid()` / reward ledger `pendingRewards` |
| `Persistence/Model/GameSave.swift` | DTO wrapper with version (+ `dungeonRun`) |
| `Persistence/Model/GameSaveData.swift` | Main game data |
| `Persistence/Model/DungeonRunSaveData.swift` | In-progress dungeon run snapshot (+ `pendingRewards`) |
| `Persistence/Model/DungeonRunRewardsSaveData.swift` | On-disk reward ledger (id-refs) ↔ runtime `DungeonRunRewards` |
| `Persistence/Model/LoadedSave.swift` | Load result `{ game, dungeonRun? }` |
| `Persistence/Model/ElfSaveData.swift` | Character save data |
| `Persistence/Model/GameSaveError.swift` | Error types |
| `Coordinator/AppCoordinator.swift` | `startGame(dungeonRun:)` restore + `resumeRoute` |
| `UILayer/Menu/MainMenuViewModel.swift` | Load trigger (exposes `loadedDungeonRun`) |

---

## Atomic Write Pattern

```swift
// FileGameRepository.save()
1. let tempURL = slotURL.appendingPathExtension("tmp")
2. try data.write(to: tempURL)                    // Write to temp
3. if fileManager.fileExists(at: slotURL) {
       try fileManager.moveItem(to: backupURL)    // Backup existing
   }
4. try fileManager.moveItem(from: tempURL, to: slotURL)  // Finalize
```

This ensures:
- No partial writes (atomic)
- Previous save preserved (backup)
- Recovery possible if crash during save

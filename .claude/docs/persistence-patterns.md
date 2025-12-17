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
public func onConfirmActionPoints() {
    gameService.advanceToNextDay()
    Task {
        try? await gameService.saveGame()
    }
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
└── data: GameSaveData
    ├── gameId: UUID
    ├── houses: [HouseSaveData]
    │   └── members: [ElfSaveData]
    │       ├── attributes, equipment slots
    │       └── inventory: InventorySaveData
    ├── gameState: GameStateSaveData
    ├── playerHouseIndex: Int
    └── playerMemberIndex: Int

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

## Auto-save Triggers

| Trigger | Location | When |
|---------|----------|------|
| Day change | `GameDayViewModel.onConfirmActionPoints()` | After spending all AP |
| App background | `ElfApp.onChange(scenePhase)` | When app goes to background/inactive |
| After battle | `DefaultBattleResultCalculator` | After battle results calculated |
| New game | `ElfGameInitializationService` | After creating new game |

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
| `Services/Persistence/GameRepository.swift` | Repository protocol |
| `Services/Persistence/Implementation/FileGameRepository.swift` | JSON implementation |
| `Services/Game/GameService.swift` | Game session protocol |
| `Services/Game/Implementation/DefaultGameService.swift` | Session management |
| `Model/Persistence/GameSave.swift` | DTO wrapper with version |
| `Model/Persistence/GameSaveData.swift` | Main game data |
| `Model/Persistence/ElfSaveData.swift` | Character save data |
| `Model/Persistence/GameSaveError.swift` | Error types |
| `UILayer/Menu/MainMenuViewModel.swift` | Load trigger |
| `UILayer/GameDay/GameDayViewModel.swift` | Save trigger |

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

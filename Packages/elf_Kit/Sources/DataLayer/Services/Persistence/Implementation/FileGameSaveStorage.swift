//
//  FileGameSaveStorage.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import Dependencies
import Foundation

// MARK: - Debug Logging

private func debugLog(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}

/// File system implementation of GameSaveStorage
/// Stores saves as JSON files in Application Support directory
public actor FileGameSaveStorage: GameSaveStorage {

    // MARK: - Constants

    private static let savesDirectoryName = "Saves"
    private static let slotsFileName = "slots.json"
    private static let slotFilePrefix = "slot_"
    private static let slotFileExtension = "json"
    private static let backupExtension = "backup"

    // MARK: - Properties

    private let saveDirectory: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let appVersion: String
    private let itemsRepository: any ItemsRepository
    private let progressionService: any ProgressionService
    private let inventoryService: any InventoryService

    /// In-memory cache of slot info for fast access
    private var slotsCache: [SaveSlotInfo]?

    // MARK: - Initialization

    public init() {
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.progressionService) var progressionService
        @Dependency(\.inventoryService) var inventoryService
        self.itemsRepository = itemsRepository
        self.progressionService = progressionService
        self.inventoryService = inventoryService

        self.fileManager = FileManager.default
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        // Setup encoder
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        // Setup decoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        // Get Application Support directory
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let elfDirectory = appSupport.appendingPathComponent("Elfy", isDirectory: true)
        self.saveDirectory = elfDirectory.appendingPathComponent(Self.savesDirectoryName, isDirectory: true)

        // Create directories if needed
        do {
            try fileManager.createDirectory(at: saveDirectory, withIntermediateDirectories: true)
            debugLog("📁 [GameSaveStorage] Save directory created/verified: \(saveDirectory.path)")
        } catch {
            debugLog("❌ [GameSaveStorage] Failed to create save directory: \(error)")
        }
    }

    // MARK: - GameSaveStorage

    // TODO: [persistence/P1] Add SHA256 checksum to GameSave and verify on load.
    // GameSaveError.checksumMismatch is already defined but never thrown — wire it up here.
    // Compute hash over encoded data, store on GameSave (new field, bump version), verify on load
    // before decoding. Catches silent disk corruption and tampered save files. Fall through to
    // .backup file on mismatch, same as the existing decode-error path.

    // TODO: [persistence/P2] Consider MessagePack/CBOR when save size becomes a concern.
    // Current JSON (.prettyPrinted + .sortedKeys) is debug-friendly but ~2-3× larger than binary
    // and significantly slower to encode for large Game graphs. Switching is a localized change:
    // swap JSONEncoder/JSONDecoder here, keep every SaveData type unchanged. Only do this if
    // profiling shows encode/decode or write time hurts UX — not sooner.

    public func save(_ game: Game, slotId: String, playTime: TimeInterval) async throws {
        debugLog("💾 [GameSaveStorage] ========== SAVE START ==========")
        debugLog("💾 [GameSaveStorage] Slot ID: \(slotId)")
        debugLog("💾 [GameSaveStorage] Game ID: \(game.id)")
        debugLog("💾 [GameSaveStorage] Houses count: \(game.houses.count)")
        debugLog("💾 [GameSaveStorage] Player house: \(game.playerHouse.name)")
        debugLog("💾 [GameSaveStorage] Current day: \(game.gameState.currentDay.dayNumber)")
        debugLog("💾 [GameSaveStorage] Play time: \(playTime)s")

        // Create GameSave DTO
        let gameSave = GameSave(from: game, playTime: playTime, appVersion: appVersion)

        // Encode to JSON
        let data: Data
        do {
            data = try encoder.encode(gameSave)
            debugLog("💾 [GameSaveStorage] Encoded to JSON, size: \(data.count) bytes")
        } catch {
            debugLog("❌ [GameSaveStorage] Encoding FAILED: \(error)")
            throw GameSaveError.encodingFailed(error)
        }

        // Write with atomic + backup strategy
        let slotURL = slotURL(for: slotId)
        let backupURL = slotURL.appendingPathExtension(Self.backupExtension)
        let tempURL = slotURL.appendingPathExtension("tmp")
        debugLog("💾 [GameSaveStorage] Target file: \(slotURL.path)")

        do {
            // 1. Write to temp file
            try data.write(to: tempURL, options: .atomic)
            debugLog("💾 [GameSaveStorage] Temp file written: \(tempURL.path)")

            // 2. Create backup of existing save
            if fileManager.fileExists(atPath: slotURL.path) {
                try? fileManager.removeItem(at: backupURL)
                try? fileManager.moveItem(at: slotURL, to: backupURL)
                debugLog("💾 [GameSaveStorage] Backup created: \(backupURL.path)")
            }

            // 3. Move temp to final location
            try fileManager.moveItem(at: tempURL, to: slotURL)
            debugLog("✅ [GameSaveStorage] Save file created: \(slotURL.path)")

            // Verify file exists
            let exists = fileManager.fileExists(atPath: slotURL.path)
            debugLog("💾 [GameSaveStorage] Verification - file exists: \(exists)")
        } catch {
            debugLog("❌ [GameSaveStorage] File write FAILED: \(error)")
            // Cleanup temp file if it exists
            try? fileManager.removeItem(at: tempURL)
            throw GameSaveError.fileWriteFailed(error)
        }

        // Update slots index
        let playerLevel = progressionService.calculateLevel(currentExp: game.player.currentExp)
        let slotInfo = SaveSlotInfo(slotId: slotId, game: game, playerLevel: playerLevel, playTime: playTime)
        try updateSlotsIndex(adding: slotInfo)
        debugLog("💾 [GameSaveStorage] Slots index updated")
        debugLog("💾 [GameSaveStorage] ========== SAVE COMPLETE ==========")
    }

    public func load(slotId: String) async throws -> Game {
        debugLog("📂 [GameSaveStorage] ========== LOAD START ==========")
        debugLog("📂 [GameSaveStorage] Slot ID: \(slotId)")

        let slotURL = slotURL(for: slotId)
        let backupURL = slotURL.appendingPathExtension(Self.backupExtension)

        debugLog("📂 [GameSaveStorage] Main file path: \(slotURL.path)")
        debugLog("📂 [GameSaveStorage] Backup file path: \(backupURL.path)")

        // Try main file first, then backup
        let urlsToTry = [slotURL, backupURL]

        for url in urlsToTry {
            let fileExists = fileManager.fileExists(atPath: url.path)
            debugLog("📂 [GameSaveStorage] Checking: \(url.lastPathComponent) - exists: \(fileExists)")

            guard fileExists else { continue }

            do {
                // Step 1: Read file
                let data = try Data(contentsOf: url)
                debugLog("📂 [GameSaveStorage] File read, size: \(data.count) bytes")

                // Step 2: Decode JSON
                let gameSave = try decoder.decode(GameSave.self, from: data)
                debugLog("📂 [GameSaveStorage] JSON decoded successfully")
                debugLog("📂 [GameSaveStorage] - Version: \(gameSave.version)")
                debugLog("📂 [GameSaveStorage] - Saved at: \(gameSave.savedAt)")
                debugLog("📂 [GameSaveStorage] - App version: \(gameSave.appVersion)")

                // Step 3: Check version and migrate if needed
                if gameSave.version < GameSave.currentVersion {
                    debugLog("📂 [GameSaveStorage] Migration needed from v\(gameSave.version) to v\(GameSave.currentVersion)")
                    return try await migrate(data: data, fromVersion: gameSave.version)
                }

                // Step 4: Convert to Game
                let game = try gameSave.toGame(
                    itemsRepository: itemsRepository,
                    inventoryService: inventoryService
                )
                debugLog("📂 [GameSaveStorage] Game object created")
                debugLog("📂 [GameSaveStorage] - Game ID: \(game.id)")
                debugLog("📂 [GameSaveStorage] - Houses: \(game.houses.count)")
                debugLog("📂 [GameSaveStorage] - Player house: \(game.playerHouse.name)")
                debugLog("✅ [GameSaveStorage] ========== LOAD COMPLETE ==========")
                return game
            } catch let error as GameSaveError {
                debugLog("❌ [GameSaveStorage] GameSaveError: \(error.errorDescription ?? "unknown")")
                // If main file failed, try backup
                if url == slotURL { continue }
                throw error
            } catch let error as DecodingError {
                debugLog("❌ [GameSaveStorage] DecodingError: \(error)")
                // Try backup on decode errors
                if url == slotURL { continue }
                throw GameSaveError.corruptedData
            } catch {
                debugLog("❌ [GameSaveStorage] Other error: \(error)")
                throw GameSaveError.fileReadFailed(error)
            }
        }

        debugLog("❌ [GameSaveStorage] No valid save file found!")
        debugLog("❌ [GameSaveStorage] ========== LOAD FAILED ==========")
        throw GameSaveError.slotNotFound(slotId)
    }

    public nonisolated func hasAnySave() -> Bool {
        let slotURL = saveDirectory.appendingPathComponent(
            "\(Self.slotFilePrefix)\(SaveSlotInfo.defaultSlotId).\(Self.slotFileExtension)"
        )
        let exists = FileManager.default.fileExists(atPath: slotURL.path)
        debugLog("🔍 [GameSaveStorage] hasAnySave() - path: \(slotURL.path) - exists: \(exists)")
        return exists
    }

    public func getPlayTime(slotId: String) async -> TimeInterval {
        let slots = listSlots()
        return slots.first { $0.slotId == slotId }?.playTime ?? 0
    }

    // MARK: - Private Helpers

    private func listSlots() -> [SaveSlotInfo] {
        if let cached = slotsCache {
            return cached
        }

        let slots = loadSlotsFromDisk()
        slotsCache = slots
        return slots
    }

    private func slotURL(for slotId: String) -> URL {
        saveDirectory.appendingPathComponent("\(Self.slotFilePrefix)\(slotId).\(Self.slotFileExtension)")
    }

    private var slotsIndexURL: URL {
        saveDirectory.appendingPathComponent(Self.slotsFileName)
    }

    private func loadSlotsFromDisk() -> [SaveSlotInfo] {
        guard fileManager.fileExists(atPath: slotsIndexURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: slotsIndexURL)
            let slots = try decoder.decode([SaveSlotInfo].self, from: data)
            return slots.sorted { $0.savedAt > $1.savedAt }
        } catch {
            return []
        }
    }

    private func updateSlotsIndex(adding slotInfo: SaveSlotInfo) throws {
        var slots = slotsCache ?? loadSlotsFromDisk()

        // Remove existing entry for this slot
        slots.removeAll { $0.slotId == slotInfo.slotId }

        // Add new entry
        slots.append(slotInfo)

        // Sort by date
        slots.sort { $0.savedAt > $1.savedAt }

        // Save to disk
        try saveSlotsIndex(slots)

        // Update cache
        slotsCache = slots
    }

    private func saveSlotsIndex(_ slots: [SaveSlotInfo]) throws {
        do {
            let data = try encoder.encode(slots)
            try data.write(to: slotsIndexURL, options: .atomic)
        } catch {
            throw GameSaveError.fileWriteFailed(error)
        }
    }

    // MARK: - Migration

    private func migrate(data: Data, fromVersion: Int) async throws -> Game {
        // Future migration logic will go here
        // For now, only version 1 exists
        switch fromVersion {
        case 1:
            // Current version, no migration needed
            let gameSave = try decoder.decode(GameSave.self, from: data)
            return try gameSave.toGame(
                itemsRepository: itemsRepository,
                inventoryService: inventoryService
            )
        default:
            throw GameSaveError.unsupportedVersion(fromVersion)
        }
    }
}

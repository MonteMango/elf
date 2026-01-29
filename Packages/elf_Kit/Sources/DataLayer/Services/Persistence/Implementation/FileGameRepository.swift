//
//  FileGameRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import Foundation

// MARK: - Debug Logging

private func debugLog(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}

/// File system implementation of GameRepository
/// Stores saves as JSON files in Application Support directory
public actor FileGameRepository: GameRepository {

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
    private let itemsRepository: ItemsRepository
    private let progressionService: ProgressionService
    private let inventoryService: InventoryService

    /// In-memory cache of slot info for fast access
    private var slotsCache: [SaveSlotInfo]?

    // MARK: - Initialization

    public init(
        itemsRepository: ItemsRepository,
        progressionService: ProgressionService,
        inventoryService: InventoryService,
        appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    ) {
        self.itemsRepository = itemsRepository
        self.progressionService = progressionService
        self.inventoryService = inventoryService
        self.fileManager = FileManager.default
        self.appVersion = appVersion

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
            debugLog("📁 [GameRepository] Save directory created/verified: \(saveDirectory.path)")
        } catch {
            debugLog("❌ [GameRepository] Failed to create save directory: \(error)")
        }
    }

    // MARK: - GameRepository

    public func save(_ game: Game, slotId: String, playTime: TimeInterval) async throws {
        debugLog("💾 [GameRepository] ========== SAVE START ==========")
        debugLog("💾 [GameRepository] Slot ID: \(slotId)")
        debugLog("💾 [GameRepository] Game ID: \(game.id)")
        debugLog("💾 [GameRepository] Houses count: \(game.houses.count)")
        debugLog("💾 [GameRepository] Player house: \(game.playerHouse.name)")
        debugLog("💾 [GameRepository] Current day: \(game.gameState.currentDay.dayNumber)")
        debugLog("💾 [GameRepository] Play time: \(playTime)s")

        // Create GameSave DTO
        let gameSave = GameSave(from: game, playTime: playTime, appVersion: appVersion)

        // Encode to JSON
        let data: Data
        do {
            data = try encoder.encode(gameSave)
            debugLog("💾 [GameRepository] Encoded to JSON, size: \(data.count) bytes")
        } catch {
            debugLog("❌ [GameRepository] Encoding FAILED: \(error)")
            throw GameSaveError.encodingFailed(error)
        }

        // Write with atomic + backup strategy
        let slotURL = slotURL(for: slotId)
        let backupURL = slotURL.appendingPathExtension(Self.backupExtension)
        let tempURL = slotURL.appendingPathExtension("tmp")
        debugLog("💾 [GameRepository] Target file: \(slotURL.path)")

        do {
            // 1. Write to temp file
            try data.write(to: tempURL, options: .atomic)
            debugLog("💾 [GameRepository] Temp file written: \(tempURL.path)")

            // 2. Create backup of existing save
            if fileManager.fileExists(atPath: slotURL.path) {
                try? fileManager.removeItem(at: backupURL)
                try? fileManager.moveItem(at: slotURL, to: backupURL)
                debugLog("💾 [GameRepository] Backup created: \(backupURL.path)")
            }

            // 3. Move temp to final location
            try fileManager.moveItem(at: tempURL, to: slotURL)
            debugLog("✅ [GameRepository] Save file created: \(slotURL.path)")

            // Verify file exists
            let exists = fileManager.fileExists(atPath: slotURL.path)
            debugLog("💾 [GameRepository] Verification - file exists: \(exists)")
        } catch {
            debugLog("❌ [GameRepository] File write FAILED: \(error)")
            // Cleanup temp file if it exists
            try? fileManager.removeItem(at: tempURL)
            throw GameSaveError.fileWriteFailed(error)
        }

        // Update slots index
        let playerLevel = progressionService.calculateLevel(currentExp: game.player.currentExp)
        let slotInfo = SaveSlotInfo(slotId: slotId, game: game, playerLevel: playerLevel, playTime: playTime)
        try updateSlotsIndex(adding: slotInfo)
        debugLog("💾 [GameRepository] Slots index updated")
        debugLog("💾 [GameRepository] ========== SAVE COMPLETE ==========")
    }

    public func load(slotId: String) async throws -> Game {
        debugLog("📂 [GameRepository] ========== LOAD START ==========")
        debugLog("📂 [GameRepository] Slot ID: \(slotId)")

        let slotURL = slotURL(for: slotId)
        let backupURL = slotURL.appendingPathExtension(Self.backupExtension)

        debugLog("📂 [GameRepository] Main file path: \(slotURL.path)")
        debugLog("📂 [GameRepository] Backup file path: \(backupURL.path)")

        // Try main file first, then backup
        let urlsToTry = [slotURL, backupURL]

        for url in urlsToTry {
            let fileExists = fileManager.fileExists(atPath: url.path)
            debugLog("📂 [GameRepository] Checking: \(url.lastPathComponent) - exists: \(fileExists)")

            guard fileExists else { continue }

            do {
                // Step 1: Read file
                let data = try Data(contentsOf: url)
                debugLog("📂 [GameRepository] File read, size: \(data.count) bytes")

                // Step 2: Decode JSON
                let gameSave = try decoder.decode(GameSave.self, from: data)
                debugLog("📂 [GameRepository] JSON decoded successfully")
                debugLog("📂 [GameRepository] - Version: \(gameSave.version)")
                debugLog("📂 [GameRepository] - Saved at: \(gameSave.savedAt)")
                debugLog("📂 [GameRepository] - App version: \(gameSave.appVersion)")

                // Step 3: Check version and migrate if needed
                if gameSave.version < GameSave.currentVersion {
                    debugLog("📂 [GameRepository] Migration needed from v\(gameSave.version) to v\(GameSave.currentVersion)")
                    return try migrate(data: data, fromVersion: gameSave.version)
                }

                // Step 4: Convert to Game
                let game = try gameSave.toGame(
                    itemsRepository: itemsRepository,
                    inventoryService: inventoryService
                )
                debugLog("📂 [GameRepository] Game object created")
                debugLog("📂 [GameRepository] - Game ID: \(game.id)")
                debugLog("📂 [GameRepository] - Houses: \(game.houses.count)")
                debugLog("📂 [GameRepository] - Player house: \(game.playerHouse.name)")
                debugLog("✅ [GameRepository] ========== LOAD COMPLETE ==========")
                return game
            } catch let error as GameSaveError {
                debugLog("❌ [GameRepository] GameSaveError: \(error.errorDescription ?? "unknown")")
                // If main file failed, try backup
                if url == slotURL { continue }
                throw error
            } catch let error as DecodingError {
                debugLog("❌ [GameRepository] DecodingError: \(error)")
                // Try backup on decode errors
                if url == slotURL { continue }
                throw GameSaveError.corruptedData
            } catch {
                debugLog("❌ [GameRepository] Other error: \(error)")
                throw GameSaveError.fileReadFailed(error)
            }
        }

        debugLog("❌ [GameRepository] No valid save file found!")
        debugLog("❌ [GameRepository] ========== LOAD FAILED ==========")
        throw GameSaveError.slotNotFound(slotId)
    }

    public nonisolated func hasAnySave() -> Bool {
        let slotURL = saveDirectory.appendingPathComponent(
            "\(Self.slotFilePrefix)\(SaveSlotInfo.defaultSlotId).\(Self.slotFileExtension)"
        )
        let exists = FileManager.default.fileExists(atPath: slotURL.path)
        debugLog("🔍 [GameRepository] hasAnySave() - path: \(slotURL.path) - exists: \(exists)")
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

    private func migrate(data: Data, fromVersion: Int) throws -> Game {
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

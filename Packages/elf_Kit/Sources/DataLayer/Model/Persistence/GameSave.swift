//
//  GameSave.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import Foundation

/// Data Transfer Object for game persistence
/// Wraps game data with versioning, timestamps, and integrity checksum
struct GameSave: Codable, Sendable {

    // MARK: - Version

    /// Current save format version
    static let currentVersion = 1

    // MARK: - Properties

    /// Save format version for migration support
    public let version: Int

    /// When this save was created
    public let savedAt: Date

    /// App version that created this save
    public let appVersion: String

    /// Total play time in seconds
    public let playTime: TimeInterval

    /// The actual game data
    public let data: GameSaveData

    /// Snapshot of an in-progress dungeon run to resume, or nil if the player
    /// was not in a dungeon when the save was written. Optional so older saves
    /// (and out-of-dungeon saves) decode with `nil`.
    public let dungeonRun: DungeonRunSaveData?

    // MARK: - Initialization

    /// Create a new GameSave from a Game object
    init(from game: Game, dungeonRun: DungeonRunSaveData?, playTime: TimeInterval, appVersion: String) {
        self.version = Self.currentVersion
        self.savedAt = Date()
        self.appVersion = appVersion
        self.playTime = playTime
        self.data = GameSaveData(from: game)
        self.dungeonRun = dungeonRun
    }

    // MARK: - Conversion

    /// Convert back to Game domain model
    func toGame(
        itemsRepository: ItemsRepository,
        inventoryService: InventoryService
    ) throws -> Game {
        try data.toGame(
            itemsRepository: itemsRepository,
            inventoryService: inventoryService
        )
    }
}

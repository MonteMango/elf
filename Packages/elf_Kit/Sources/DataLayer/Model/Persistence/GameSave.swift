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

    // MARK: - Initialization

    /// Create a new GameSave from a Game object
    init(from game: Game, playTime: TimeInterval, appVersion: String) {
        self.version = Self.currentVersion
        self.savedAt = Date()
        self.appVersion = appVersion
        self.playTime = playTime
        self.data = GameSaveData(from: game)
    }

    // MARK: - Conversion

    /// Convert back to Game domain model
    func toGame(
        itemsRepository: ItemsRepository,
        inventoryService: InventoryService
    ) async throws -> Game {
        try await data.toGame(
            itemsRepository: itemsRepository,
            inventoryService: inventoryService
        )
    }
}

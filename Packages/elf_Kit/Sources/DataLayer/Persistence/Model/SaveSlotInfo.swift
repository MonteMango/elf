//
//  SaveSlotInfo.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import Foundation

/// Metadata about a save slot for quick listing without loading full game data
/// Stored separately in slots.json for fast access
public struct SaveSlotInfo: Codable, Identifiable, Sendable {

    // MARK: - Properties

    /// Unique slot identifier
    public let slotId: String

    /// When the save was last updated
    public let savedAt: Date

    /// Total play time in seconds
    public let playTime: TimeInterval

    /// Current game day number
    public let currentDay: Int

    /// Player character name
    public let playerName: String

    /// Player character level (1-12)
    public let playerLevel: Int

    /// Player's house name
    public let houseName: String

    // MARK: - Identifiable

    public var id: String { slotId }

    // MARK: - Convenience

    /// Create slot info from a Game object
    /// - Parameters:
    ///   - slotId: Unique slot identifier
    ///   - game: Game object
    ///   - playerLevel: Player's level (calculated via ProgressionService)
    ///   - playTime: Total play time in seconds
    public init(slotId: String, game: Game, playerLevel: Int, playTime: TimeInterval) {
        self.slotId = slotId
        self.savedAt = Date()
        self.playTime = playTime
        self.currentDay = game.gameState.currentDay.dayNumber
        self.playerName = game.player.name
        self.playerLevel = playerLevel
        self.houseName = game.playerHouse.name
    }
}

// MARK: - Default Slot

public extension SaveSlotInfo {
    /// Default slot ID for single-slot saves
    static let defaultSlotId = "default"
}

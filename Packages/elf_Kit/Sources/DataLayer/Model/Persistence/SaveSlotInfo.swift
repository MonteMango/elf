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

    /// Player character level
    public let playerLevel: Int16

    /// Player's house name
    public let houseName: String

    // MARK: - Identifiable

    public var id: String { slotId }

    // MARK: - Initialization

    public init(
        slotId: String,
        savedAt: Date,
        playTime: TimeInterval,
        currentDay: Int,
        playerName: String,
        playerLevel: Int16,
        houseName: String
    ) {
        self.slotId = slotId
        self.savedAt = savedAt
        self.playTime = playTime
        self.currentDay = currentDay
        self.playerName = playerName
        self.playerLevel = playerLevel
        self.houseName = houseName
    }

    // MARK: - Convenience

    /// Create slot info from a Game object
    public init(slotId: String, game: Game, playTime: TimeInterval) {
        self.slotId = slotId
        self.savedAt = Date()
        self.playTime = playTime
        self.currentDay = game.gameState.currentDay.dayNumber
        self.playerName = game.player.name
        self.playerLevel = game.player.level
        self.houseName = game.playerHouse.name
    }
}

// MARK: - Default Slot

public extension SaveSlotInfo {
    /// Default slot ID for single-slot saves
    static let defaultSlotId = "default"
}

//
//  GameRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import Foundation

/// Repository protocol for game persistence
/// Abstracts storage implementation (file system, cloud, etc.)
public protocol GameRepository: Sendable {

    /// Save a game to a specific slot
    /// - Parameters:
    ///   - game: The game to save
    ///   - slotId: Unique slot identifier
    ///   - playTime: Total play time in seconds
    func save(_ game: Game, slotId: String, playTime: TimeInterval) async throws

    /// Load a game from a specific slot
    /// - Parameter slotId: The slot identifier to load from
    /// - Returns: The loaded game
    func load(slotId: String) async throws -> Game

    /// Get list of all save slots with metadata
    /// - Returns: Array of slot info sorted by save date (newest first)
    func listSlots() async -> [SaveSlotInfo]

    /// Delete a specific save slot
    /// - Parameter slotId: The slot identifier to delete
    func deleteSlot(_ slotId: String) async throws

    /// Check if any saves exist
    /// - Returns: True if at least one save exists
    func hasAnySave() -> Bool

    /// Check if a specific slot exists
    /// - Parameter slotId: The slot identifier to check
    /// - Returns: True if the slot exists
    func hasSlot(_ slotId: String) -> Bool

    /// Get play time for a specific slot
    /// - Parameter slotId: The slot identifier
    /// - Returns: Play time in seconds, or 0 if slot doesn't exist
    func getPlayTime(slotId: String) async -> TimeInterval
}

// MARK: - Convenience Extension

public extension GameRepository {

    /// Save to default slot
    func save(_ game: Game, playTime: TimeInterval) async throws {
        try await save(game, slotId: SaveSlotInfo.defaultSlotId, playTime: playTime)
    }

    /// Load from default slot
    func loadDefault() async throws -> Game {
        try await load(slotId: SaveSlotInfo.defaultSlotId)
    }

    /// Delete default slot
    func deleteDefault() async throws {
        try await deleteSlot(SaveSlotInfo.defaultSlotId)
    }

    /// Check if default slot exists
    func hasDefaultSave() -> Bool {
        hasSlot(SaveSlotInfo.defaultSlotId)
    }
}

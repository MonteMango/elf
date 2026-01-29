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

    /// Check if any saves exist
    /// - Returns: True if at least one save exists
    func hasAnySave() -> Bool

    /// Get play time for a specific slot
    /// - Parameter slotId: The slot identifier
    /// - Returns: Play time in seconds, or 0 if slot doesn't exist
    func getPlayTime(slotId: String) async -> TimeInterval
}

// MARK: - Convenience Extension

public extension GameRepository {

    /// Load from default slot
    func loadDefault() async throws -> Game {
        try await load(slotId: SaveSlotInfo.defaultSlotId)
    }

}

//
//  GameSaveStorage.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import Foundation

/// Repository protocol for game persistence
/// Abstracts storage implementation (file system, cloud, etc.)
public protocol GameSaveStorage: Sendable {

    /// Save a game (and any in-progress dungeon run) to a specific slot
    /// - Parameters:
    ///   - game: The game to save
    ///   - dungeonRun: Snapshot of an active dungeon run, or nil if not in one
    ///   - slotId: Unique slot identifier
    ///   - playTime: Total play time in seconds
    func save(_ game: Game, dungeonRun: DungeonRunSaveData?, slotId: String, playTime: TimeInterval) async throws

    /// Load a game (and any saved dungeon run) from a specific slot
    /// - Parameter slotId: The slot identifier to load from
    /// - Returns: The loaded game plus optional dungeon run
    func load(slotId: String) async throws -> LoadedSave

    /// Check if any saves exist
    /// - Returns: True if at least one save exists
    func hasAnySave() -> Bool

    /// Get play time for a specific slot
    /// - Parameter slotId: The slot identifier
    /// - Returns: Play time in seconds, or 0 if slot doesn't exist
    func getPlayTime(slotId: String) async -> TimeInterval
}

// MARK: - Convenience Extension

public extension GameSaveStorage {

    /// Save a game with no active dungeon run.
    func save(_ game: Game, slotId: String, playTime: TimeInterval) async throws {
        try await save(game, dungeonRun: nil, slotId: slotId, playTime: playTime)
    }

    /// Load from default slot
    func loadDefault() async throws -> LoadedSave {
        try await load(slotId: SaveSlotInfo.defaultSlotId)
    }

}

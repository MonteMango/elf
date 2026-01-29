//
//  GameInitializationService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

// MARK: - GameInitializationError

enum GameInitializationError: Error, LocalizedError {
    case failedToCreateHouses
    case failedToSaveGame(Error)

    public var errorDescription: String? {
        switch self {
        case .failedToCreateHouses:
            return "Failed to create houses for the game"
        case .failedToSaveGame(let error):
            return "Failed to save game: \(error.localizedDescription)"
        }
    }
}

// MARK: - GameInitializationService

/// Service for creating and initializing a new game
/// Handles house creation, calendar generation, and initial save
public protocol GameInitializationService: Sendable {

    /// Create a new game with the given player character
    /// - Parameters:
    ///   - playerCharacter: The player's created character
    /// - Returns: A fully initialized Game object
    /// - Throws: GameInitializationError if creation fails
    func createNewGame(
        playerCharacter: PlayerCharacter
    ) async throws -> Game
}

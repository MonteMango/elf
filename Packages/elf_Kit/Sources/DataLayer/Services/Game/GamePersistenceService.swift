//
//  GamePersistenceService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.01.26.
//

import Foundation

/// Protocol for game persistence operations
/// Note: Currently @MainActor because DefaultGameService is @MainActor.
/// The actual file I/O is handled by actor-isolated FileGameRepository (runs on background).
@MainActor
public protocol GamePersistenceService: AnyObject {

    /// Saves the current game state
    /// File I/O is handled by actor-isolated repository (runs on background thread)
    func saveGame() async throws
}

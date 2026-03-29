//
//  GamePersistenceService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.01.26.
//

import Foundation

/// Protocol for game persistence operations
/// File I/O is handled by actor-isolated FileGameSaveStorage (runs on background)
public protocol GamePersistenceService: Sendable {

    /// Saves the current game state
    func saveGame() async throws
}

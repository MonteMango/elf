//
//  DebugGameLogger.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Service for debug logging of game state on save
///
/// This protocol provides a method to log game state details
/// for debugging purposes. Implementations can output to console
/// or be no-op when categories are empty.
///
/// **Usage**:
/// Use `ConsoleDebugGameLogger` with specific categories to enable logging,
/// or with an empty set for zero output.
public protocol DebugGameLogger: Sendable {

    /// Logs game state details before saving
    ///
    /// - Parameters:
    ///   - game: The full Game struct being saved
    ///   - playTime: Total play time in seconds
    func logGameSave(game: Game, playTime: TimeInterval)
}

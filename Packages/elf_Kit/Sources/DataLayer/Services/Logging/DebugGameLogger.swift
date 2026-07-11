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

    /// Logs a summary of a completed world turn (AI elves' day).
    ///
    /// - Parameter outcome: The combined result of every bot's turn.
    func logWorldTurn(_ outcome: WorldTurnOutcome)

    /// Logs a one-off diagnostic error message (e.g. a swallowed background
    /// save failure). The console implementation compiles its output out
    /// entirely in non-DEBUG builds — callers do not need to gate the call
    /// themselves.
    ///
    /// - Parameter message: The error message to log.
    func logError(_ message: String)

    /// Logs a one-off diagnostic informational message (e.g. a UI action
    /// trace, a non-error lifecycle event) — same DEBUG-only output policy as
    /// `logError`, without the error-severity framing.
    ///
    /// - Parameter message: The message to log.
    func logDebug(_ message: String)
}

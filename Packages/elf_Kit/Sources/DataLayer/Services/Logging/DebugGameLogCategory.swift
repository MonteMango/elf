//
//  DebugGameLogCategory.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Categories for debug game logging to control what information is displayed on save
///
/// Use a Set of these categories when initializing ConsoleDebugGameLogger to
/// control which types of game information are logged to console.
///
/// Example usage:
/// ```swift
/// let logger = ConsoleDebugGameLogger(categories: [
///     .playerInfo,
///     .inventory,
///     .equipment
/// ])
/// ```
public enum DebugGameLogCategory: Sendable {
    /// Log player identity and progression: name, exp, HP/MP, reputation
    case playerInfo

    /// Log game state: current day, action points, calendar progress
    case gameState

    /// Log all inventory items with names, IDs, tiers, quantities
    case inventory

    /// Log equipped item slots with item names and stats
    case equipment

    /// Log house names, eliminated status
    case houses

    /// Log the per-turn world simulation: bot count, battles won, exp/drops
    case worldTurn
}

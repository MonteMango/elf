//
//  GameStateService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.01.26.
//

import Foundation

/// Protocol for managing game state mutations
/// Actor-isolated: all access is serialized for thread safety
public protocol GameStateService: Sendable {

    // MARK: - Game State

    /// Current game state (actor-isolated, requires await)
    var game: Game { get async }

    /// Thread-safe synchronous snapshot of current game state.
    /// Use for ViewModel initialization; use gameUpdates() for reactive observation.
    var currentGame: Game { get }

    /// Stream of game state changes for reactive observation
    func gameUpdates() async -> AsyncStream<Game>

    // MARK: - Day Management

    /// Advances to the next day in the game
    func advanceToNextDay() async

    /// Spends action points for an activity
    /// - Parameter amount: Number of action points to spend
    func spendActionPoints(_ amount: Int) async

    // MARK: - Player Progression

    /// Adds experience points to the player
    /// Level is computed automatically from total XP (TDD: single source of truth)
    /// - Parameter amount: Experience points to add
    func addPlayerExperience(_ amount: Int) async

    /// Adds fishing experience to the player
    /// - Parameter amount: Fishing XP to add
    func addFishingExperience(_ amount: Int) async

    /// Adds foraging experience to the player
    /// - Parameter amount: Foraging XP to add
    func addForagingExperience(_ amount: Int) async

    /// Adds mining experience to the player
    /// - Parameter amount: Mining XP to add
    func addMiningExperience(_ amount: Int) async

    /// Adds hunt rewards (drops) to player's inventory
    /// - Parameter rewards: Hunt rewards containing materials, weapon, and armor drops
    func addDropsToPlayerInventory(rewards: HuntRewards) async

    /// Adds caught fish to player's inventory as materials
    /// - Parameter fish: Array of fish to add
    func addFishToInventory(_ fish: [Fish]) async

    /// Adds gathered herbs to player's inventory as materials
    /// - Parameter herbs: Array of herbs to add
    func addHerbsToInventory(_ herbs: [Herb]) async

    /// Adds mined ores to player's inventory as materials
    /// - Parameter ores: Array of ores to add
    func addOresToInventory(_ ores: [Ore]) async

    // MARK: - Atomic Player Modification

    /// Atomically reads and modifies player state within actor isolation.
    /// Guarantees no state changes between read and write (no suspension points).
    func modifyPlayer(_ transform: @Sendable (inout ElfInfo) -> Void) async

}

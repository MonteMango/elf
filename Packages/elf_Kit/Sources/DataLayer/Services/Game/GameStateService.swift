//
//  GameStateService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.01.26.
//

import Foundation

/// Protocol for managing game state mutations
/// All methods require MainActor because they mutate @Observable state
@MainActor
public protocol GameStateService: AnyObject {

    // MARK: - Game State

    /// Current game state
    var game: Game { get }

    /// Stream of game state changes for reactive observation
    func gameUpdates() -> AsyncStream<Game>

    // MARK: - Day Management

    /// Advances to the next day in the game
    func advanceToNextDay()

    /// Spends action points for an activity
    /// - Parameter amount: Number of action points to spend
    func spendActionPoints(_ amount: Int)

    // MARK: - Player Progression

    /// Adds experience points to the player
    /// Level is computed automatically from total XP (TDD: single source of truth)
    /// - Parameter amount: Experience points to add
    func addPlayerExperience(_ amount: Int)

    /// Adds fishing experience to the player
    /// - Parameter amount: Fishing XP to add
    func addFishingExperience(_ amount: Int)

    /// Adds foraging experience to the player
    /// - Parameter amount: Foraging XP to add
    func addForagingExperience(_ amount: Int)

    /// Adds mining experience to the player
    /// - Parameter amount: Mining XP to add
    func addMiningExperience(_ amount: Int)

    /// Adds hunt rewards (drops) to player's inventory
    /// - Parameter rewards: Hunt rewards containing materials, weapon, and armor drops
    func addDropsToPlayerInventory(rewards: HuntRewards) async

    /// Adds caught fish to player's inventory as materials
    /// - Parameter fish: Array of fish to add
    func addFishToInventory(_ fish: [Fish])

    /// Adds gathered herbs to player's inventory as materials
    /// - Parameter herbs: Array of herbs to add
    func addHerbsToInventory(_ herbs: [Herb])

    /// Adds mined ores to player's inventory as materials
    /// - Parameter ores: Array of ores to add
    func addOresToInventory(_ ores: [Ore])

    // MARK: - Player Equipment

    /// Sets the weapon configuration (weapon, shield, dual-wield, etc.)
    func setWeaponConfiguration(_ config: WeaponConfiguration)

    /// Equips or unequips armor in the specified slot
    func equipArmor(_ armor: ElfDefenseItem?, slot: ArmorSlot)

    /// Equips or unequips jewelry in the specified slot
    func equipJewelry(_ jewelry: ElfJewelryItem?, slot: JewelrySlot)

    /// Equips or unequips a shirt
    func equipShirt(_ shirt: ElfRobeItem?)

    // MARK: - Crafting

    /// Applies crafting result by replacing player inventory
    func applyCraftResult(_ inventory: ElfInventory)
}

//
//  GameService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation
import Observation

/// Mutation-only protocol for game state operations. State storage lives in
/// `GameStore`; this service operates on a store reference and applies BL
/// rules (level recovery, inventory aggregation, crafting, etc.).
///
/// Main-actor-isolated: mutations are synchronous from the UI thread. Hidden
/// behind `GameSession` — views never touch `GameService` directly.
@MainActor
public protocol GameService: AnyObject, Observable {

    // MARK: - Day Management

    /// Advances to the next day in the calendar. Resets action points.
    func advanceToNextDay()

    /// Spends action points for an activity.
    /// - Parameter amount: Number of action points to spend (no-op if insufficient).
    func spendActionPoints(_ amount: Int)

    // MARK: - Player Progression

    /// Adds experience points to the player.
    func addPlayerExperience(_ amount: Int)

    /// Adds fishing experience to the player.
    func addFishingExperience(_ amount: Int)

    /// Adds foraging experience to the player.
    func addForagingExperience(_ amount: Int)

    /// Adds mining experience to the player.
    func addMiningExperience(_ amount: Int)

    /// Adds hunt rewards (drops) to player's inventory.
    func addDropsToPlayerInventory(rewards: HuntRewards)

    /// Adds caught fish to player's inventory as materials.
    func addFishToInventory(_ fish: [Fish])

    /// Adds gathered herbs to player's inventory as materials.
    func addHerbsToInventory(_ herbs: [Herb])

    /// Adds mined ores to player's inventory as materials.
    func addOresToInventory(_ ores: [Ore])

    /// Adds the given hero items to the player's inventory, routed by concrete type
    /// (weapon / armor / shield / robe). Used by dev shortcuts that seed equipment in bulk.
    func addItemsToPlayerInventory(_ items: [Item])

    // MARK: - Crafting

    /// Atomically crafts `item` from `recipe`: validates materials, deducts
    /// ingredients, and adds the crafted item to inventory. Returns `true` on
    /// success, `false` if materials are insufficient.
    @discardableResult
    func craftItem(recipe: Recipe, item: Item) -> Bool
}

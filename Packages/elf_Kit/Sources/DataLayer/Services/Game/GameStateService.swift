//
//  GameStateService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.01.26.
//

import Foundation
import Observation

/// Protocol for managing game state mutations.
///
/// Main-actor-isolated: UI state lives on main thread. Mutations are synchronous
/// (fast in-memory state transitions). SwiftUI observation works per-property via
/// the `@Observable` macro on conforming types.
@MainActor
public protocol GameStateService: AnyObject, Observable {

    // MARK: - Observable State

    /// Current action points (current/maximum)
    var actionPoints: ActionPoints { get }

    /// Current in-game day
    var currentDay: GameDay { get }

    /// Full calendar for the season
    var calendar: [GameDay] { get }

    /// All houses (including the player's)
    var houses: [House] { get }

    /// Index of the player's house within `houses`
    var playerHouseIndex: Int { get }

    /// Index of the player within their house's members
    var playerMemberIndex: Int { get }

    /// Player state as a nested observable store (granular field-level tracking).
    var player: PlayerStore { get }

    // MARK: - Derived

    /// Whether the current day is the last one in the calendar
    var isLastDay: Bool { get }

    /// Days following `currentDay` in the calendar (up to `upcomingDaysCount`)
    var upcomingDays: [GameDay] { get }

    // MARK: - Snapshot

    /// Extracts the current state as a value-type `Game`. Used for persistence.
    func snapshot() -> Game

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

    // MARK: - Atomic Scoped Mutations

    /// Atomically mutates the player's equipped items.
    ///
    /// Fires observation invalidation only for `PlayerStore.equipped`. Views that
    /// read unrelated fields (e.g. `player.foragingExp`) are not re-evaluated.
    func modifyEquipment(_ transform: (inout EquippedItems) -> Void)

    /// Atomically mutates the player's inventory.
    ///
    /// Fires observation invalidation only for `PlayerStore.inventory`. Use this
    /// for crafting, drops, and any operation that changes inventory without
    /// touching other player fields.
    func modifyInventory(_ transform: (inout ElfInventory) -> Void)
}

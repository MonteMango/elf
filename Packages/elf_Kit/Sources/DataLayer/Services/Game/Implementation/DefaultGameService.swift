//
//  DefaultGameService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import Foundation
import Observation

/// Default implementation of `GameService`.
///
/// Main-actor-isolated and `@Observable`: SwiftUI tracks access per-property, and
/// mutations run synchronously on the main thread. `Game` stays a pure value type,
/// reconstructed from the store via `snapshot()` at persistence time.
///
/// Heavy work (disk I/O via `gameRepository`) still runs on a background actor —
/// the `await` in `saveGame()` releases the main thread while the write happens.
@MainActor
@Observable
public final class DefaultGameService: GameService {

    // MARK: - Observable State

    public private(set) var actionPoints: ActionPoints
    public private(set) var currentDay: GameDay
    public private(set) var calendar: [GameDay]
    public private(set) var houses: [House]
    public let playerHouseIndex: Int
    public let playerMemberIndex: Int
    public let gameId: UUID
    public private(set) var playTime: TimeInterval

    /// Nested observable store for the player's state (per-field tracking).
    public let player: PlayerStore

    // MARK: - Derived

    public var isLastDay: Bool {
        guard let lastDay = calendar.last else { return false }
        return currentDay.dayNumber >= lastDay.dayNumber
    }

    public var upcomingDays: [GameDay] {
        guard let currentIndex = calendar.firstIndex(where: { $0.dayNumber == currentDay.dayNumber }) else {
            return []
        }
        let nextIndex = currentIndex + 1
        guard nextIndex < calendar.count else { return [] }
        let endIndex = min(nextIndex + GameMechanicsConstants.upcomingDaysCount, calendar.count)
        return Array(calendar[nextIndex..<endIndex])
    }

    // MARK: - Dependencies

    @ObservationIgnored private let gameRepository: GameSaveStorage
    @ObservationIgnored private let inventoryService: InventoryService
    @ObservationIgnored private let craftService: CraftService
    @ObservationIgnored private let debugGameLogger: DebugGameLogger
    @ObservationIgnored private let slotId: String

    // MARK: - Initialization

    public init(
        game: Game,
        gameRepository: GameSaveStorage,
        inventoryService: InventoryService,
        craftService: CraftService,
        debugGameLogger: DebugGameLogger,
        slotId: String = SaveSlotInfo.defaultSlotId,
        playTime: TimeInterval = 0
    ) {
        self.gameId = game.id
        self.actionPoints = game.gameState.actionPoints
        self.currentDay = game.gameState.currentDay
        self.calendar = game.gameState.calendar
        self.houses = game.houses
        self.playerHouseIndex = game.playerHouseIndex
        self.playerMemberIndex = game.playerMemberIndex
        self.player = PlayerStore(from: game.houses[game.playerHouseIndex].members[game.playerMemberIndex])
        self.gameRepository = gameRepository
        self.inventoryService = inventoryService
        self.craftService = craftService
        self.debugGameLogger = debugGameLogger
        self.slotId = slotId
        self.playTime = playTime
    }

    // MARK: - Snapshot

    /// Reconstructs the current state as a value-type `Game`. Used when persisting.
    public func snapshot() -> Game {
        var updatedHouses = houses
        updatedHouses[playerHouseIndex].members[playerMemberIndex] = player.snapshot()
        return Game(
            id: gameId,
            houses: updatedHouses,
            gameState: GameState(
                currentDay: currentDay,
                actionPoints: actionPoints,
                calendar: calendar
            ),
            playerHouseIndex: playerHouseIndex,
            playerMemberIndex: playerMemberIndex
        )
    }

    // MARK: - Day Management

    public func advanceToNextDay() {
        let nextDayNumber = currentDay.dayNumber + 1
        guard let nextDayIndex = calendar.firstIndex(where: { $0.dayNumber == nextDayNumber }) else {
            return // No more days (game finished)
        }
        currentDay = calendar[nextDayIndex]
        actionPoints = actionPoints.reset()
    }

    public func spendActionPoints(_ amount: Int) {
        if case .success(let newPoints) = actionPoints.spend(amount) {
            actionPoints = newPoints
        }
    }

    // MARK: - Player Progression

    public func addPlayerExperience(_ amount: Int) {
        player.currentExp += amount
    }

    public func addFishingExperience(_ amount: Int) {
        player.fishingExp += amount
    }

    public func addForagingExperience(_ amount: Int) {
        player.foragingExp += amount
    }

    public func addMiningExperience(_ amount: Int) {
        player.miningExp += amount
    }

    public func addDropsToPlayerInventory(rewards: HuntRewards) {
        var inventory = player.inventory
        for material in rewards.materials {
            inventory = inventoryService.addMaterial(
                id: material.id,
                source: .monster,
                quantity: material.amount,
                to: inventory
            )
        }
        if let weapon = rewards.weapon {
            inventory = inventoryService.addWeapon(weapon, to: inventory)
        }
        if let armor = rewards.armor {
            inventory = inventoryService.addArmor(armor, to: inventory)
        }
        player.inventory = inventory
    }

    public func addFishToInventory(_ fish: [Fish]) {
        var inventory = player.inventory
        for f in fish {
            inventory = inventoryService.addMaterial(
                id: f.id.rawValue,
                source: .fish,
                quantity: 1,
                to: inventory
            )
        }
        player.inventory = inventory
    }

    public func addHerbsToInventory(_ herbs: [Herb]) {
        var inventory = player.inventory
        for herb in herbs {
            inventory = inventoryService.addMaterial(
                id: herb.id.rawValue,
                source: .herb,
                quantity: 1,
                to: inventory
            )
        }
        player.inventory = inventory
    }

    public func addOresToInventory(_ ores: [Ore]) {
        var inventory = player.inventory
        for ore in ores {
            inventory = inventoryService.addMaterial(
                id: ore.id.rawValue,
                source: .ore,
                quantity: 1,
                to: inventory
            )
        }
        player.inventory = inventory
    }

    public func addItemsToPlayerInventory(_ items: [Item]) {
        var inventory = player.inventory
        for item in items {
            inventory = inventoryService.addCraftedItem(item, to: inventory)
        }
        player.inventory = inventory
    }

    // MARK: - Crafting

    /// Atomically validates, deducts materials, and adds the crafted item to inventory.
    /// Returns `true` on success, `false` if materials are insufficient.
    @discardableResult
    public func craftItem(recipe: Recipe, item: Item) -> Bool {
        var inventory = player.inventory
        guard craftService.canCraft(recipe: recipe, inventory: inventory) else { return false }
        inventory = craftService.deductMaterials(recipe: recipe, from: inventory)
        inventory = inventoryService.addCraftedItem(item, to: inventory)
        player.inventory = inventory
        return true
    }

    // MARK: - Persistence

    // TODO: [persistence/P0] Coalesce/debounce rapid saveGame() calls.
    // Currently each caller awaits a full serialize+atomic-write round-trip. If several UI events
    // fire in quick succession (battle tick, AP spend, quest update) we perform N serial writes of
    // essentially the same Game snapshot. Options (pick one):
    //   1. Debounce: cancel a pending Task and reschedule with ~200ms delay; flush immediately on
    //      scenePhase.background / exitGame / battle end.
    //   2. Dirty flag + periodic flush: set isDirty on mutation, flush at a fixed interval (1-2s)
    //      plus explicit flushNow() for critical checkpoints.
    // Must preserve the "save-before-exit" contract used by scenePhase.background and exitGame().
    public func saveGame() async throws {
        let snap = snapshot()
        let time = playTime
        debugGameLogger.logGameSave(game: snap, playTime: time)
        try await gameRepository.save(snap, slotId: slotId, playTime: time)
    }
}

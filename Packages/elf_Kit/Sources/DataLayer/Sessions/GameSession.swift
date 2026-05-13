//
//  GameSession.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Public facade for an active game session. Owns the observable `state`
/// (`GameStore`), the dungeon child session, the day-state shortcut, and
/// every game-level mutation + persistence operation.
///
/// Views and ViewModels go through `GameSession` exclusively. State reads via
/// `session.state.X`; mutations via `session.X(...)`; persistence via
/// `session.save()`. There is no separate "service" layer underneath — the
/// mutation logic lives directly in this type.
///
/// Lifecycle: created when a game starts, released when it ends (see
/// `AppCoordinator.startGame` / `endGame`).
@MainActor
@Observable
public final class GameSession {

    // MARK: - State

    public let state: GameStore

    // MARK: - Child sessions

    public var dungeonSession: DungeonSession?

    // MARK: - Private dependencies

    private let gameRepository: any GameSaveStorage
    private let debugGameLogger: any DebugGameLogger
    private let inventoryService: any InventoryService
    private let craftService: any CraftService

    private let slotId: String

    // MARK: - Initialization

    public init(
        game: Game,
        playTime: TimeInterval = 0,
        slotId: String = SaveSlotInfo.defaultSlotId
    ) {
        @Dependency(\.gameRepository) var gameRepository
        @Dependency(\.debugGameLogger) var debugGameLogger
        @Dependency(\.inventoryService) var inventoryService
        @Dependency(\.craftService) var craftService
        self.gameRepository = gameRepository
        self.debugGameLogger = debugGameLogger
        self.inventoryService = inventoryService
        self.craftService = craftService
        self.state = GameStore(from: game, playTime: playTime)
        self.slotId = slotId
    }

    // MARK: - Day Management

    /// Advances to the next day in the calendar. Resets action points.
    public func advanceToNextDay() {
        let nextDayNumber = state.currentDay.dayNumber + 1
        guard let nextDayIndex = state.calendar.firstIndex(where: { $0.dayNumber == nextDayNumber }) else {
            return
        }
        state.currentDay = state.calendar[nextDayIndex]
        state.actionPoints = state.actionPoints.reset()
    }

    /// Spends action points for an activity. No-op if insufficient.
    public func spendActionPoints(_ amount: Int) {
        if case .success(let newPoints) = state.actionPoints.spend(amount) {
            state.actionPoints = newPoints
        }
    }

    // MARK: - Player Progression

    public func addPlayerExperience(_ amount: Int) {
        state.player.currentExp += amount
    }

    public func addFishingExperience(_ amount: Int) {
        state.player.fishingExp += amount
    }

    public func addForagingExperience(_ amount: Int) {
        state.player.foragingExp += amount
    }

    public func addMiningExperience(_ amount: Int) {
        state.player.miningExp += amount
    }

    /// Adds hunt rewards (drops) to the player's inventory.
    public func addDropsToPlayerInventory(rewards: HuntRewards) {
        let additions = rewards.materials.map {
            MaterialAddition(id: $0.id, source: .monster, quantity: $0.amount)
        }
        var inventory = inventoryService.addMaterials(additions, to: state.player.inventory)
        if let weapon = rewards.weapon {
            inventory = inventoryService.addWeapon(weapon, to: inventory)
        }
        if let armor = rewards.armor {
            inventory = inventoryService.addArmor(armor, to: inventory)
        }
        state.player.inventory = inventory
    }

    /// Adds caught fish to the player's inventory as materials.
    public func addFishToInventory(_ fish: [Fish]) {
        let additions = fish.map {
            MaterialAddition(id: $0.id.rawValue, source: .fish, quantity: 1)
        }
        state.player.inventory = inventoryService.addMaterials(additions, to: state.player.inventory)
    }

    /// Adds gathered herbs to the player's inventory as materials.
    public func addHerbsToInventory(_ herbs: [Herb]) {
        let additions = herbs.map {
            MaterialAddition(id: $0.id.rawValue, source: .herb, quantity: 1)
        }
        state.player.inventory = inventoryService.addMaterials(additions, to: state.player.inventory)
    }

    /// Adds mined ores to the player's inventory as materials.
    public func addOresToInventory(_ ores: [Ore]) {
        let additions = ores.map {
            MaterialAddition(id: $0.id.rawValue, source: .ore, quantity: 1)
        }
        state.player.inventory = inventoryService.addMaterials(additions, to: state.player.inventory)
    }

    /// Adds the given hero items to the player's inventory, routed by concrete
    /// type (weapon / armor / shield / robe). Used by dev shortcuts that seed
    /// equipment in bulk.
    public func addItemsToPlayerInventory(_ items: [Item]) {
        var inventory = state.player.inventory
        for item in items {
            inventory = inventoryService.addCraftedItem(item, to: inventory)
        }
        state.player.inventory = inventory
    }

    // MARK: - Crafting

    /// Atomically crafts `item` from `recipe`: validates materials, deducts
    /// ingredients, and adds the crafted item to inventory. Returns `true` on
    /// success, `false` if materials are insufficient.
    @discardableResult
    public func craftItem(recipe: Recipe, item: Item) -> Bool {
        var inventory = state.player.inventory
        guard craftService.canCraft(recipe: recipe, inventory: inventory) else { return false }
        inventory = craftService.deductMaterials(recipe: recipe, from: inventory)
        inventory = inventoryService.addCraftedItem(item, to: inventory)
        state.player.inventory = inventory
        return true
    }

    // MARK: - Persistence

    /// Saves the active game state. Snapshots the store on the main thread,
    /// then offloads disk I/O to the repository (background actor).
    // TODO: [persistence/P0] Coalesce/debounce rapid save() calls.
    public func save() async throws {
        let snap = state.snapshot()
        let time = state.playTime
        debugGameLogger.logGameSave(game: snap, playTime: time)
        try await gameRepository.save(snap, slotId: slotId, playTime: time)
    }

    // MARK: - Dungeon Session Lifecycle

    @discardableResult
    public func startDungeonSession(dungeonId: UUID, allyIds: [UUID]) -> DungeonSession {
        let session = DungeonSession(
            gameStore: state,
            dungeonId: dungeonId,
            allyIds: allyIds
        )
        dungeonSession = session
        return session
    }

    public func endDungeonSession() {
        dungeonSession = nil
    }
}

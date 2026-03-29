//
//  DefaultGameService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import Foundation
import os

/// Default implementation of GameService
/// Actor-isolated: all game state mutations are serialized for thread safety
/// Uses AsyncStream to broadcast changes, OSAllocatedUnfairLock for sync reads
public actor DefaultGameService: @preconcurrency GameService {

    // MARK: - Properties

    // TODO: - Performance: Game struct copying & comparison will degrade with scale.
    // Currently 80 characters (8 houses × 10 members), each with inventory & equipment.
    // Every mutation copies the entire Game struct, runs O(total state) Equatable check,
    // and broadcasts the full copy to all subscribers.
    // When scaling to hundreds of characters with large inventories, consider splitting Game
    // into granular domains (gameState, houses, per-character access) so mutations, comparisons,
    // and subscriptions are scoped to only what changed.
    public private(set) var game: Game {
        didSet {
            guard game != oldValue else { return }
            let snapshot = game
            gameSnapshot.withLock { $0 = snapshot }
            for continuation in continuations.values {
                continuation.yield(snapshot)
            }
        }
    }

    public private(set) var playTime: TimeInterval

    // MARK: - Sync Snapshot

    private let gameSnapshot: OSAllocatedUnfairLock<Game>

    /// Thread-safe synchronous read of current game state.
    /// Use for VM initialization; use gameUpdates() for reactive observation.
    nonisolated public var currentGame: Game {
        gameSnapshot.withLock { $0 }
    }

    // MARK: - Stream

    private var continuations: [UUID: AsyncStream<Game>.Continuation] = [:]

    public func gameUpdates() -> AsyncStream<Game> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeContinuation(id)
                }
            }
        }
    }

    private func removeContinuation(_ id: UUID) {
        continuations.removeValue(forKey: id)
    }

    // MARK: - Player Access

    private var player: ElfInfo {
        get { game.houses[game.playerHouseIndex].members[game.playerMemberIndex] }
        set { game.houses[game.playerHouseIndex].members[game.playerMemberIndex] = newValue }
    }

    // MARK: - Dependencies

    private let gameRepository: GameSaveStorage
    private let itemsRepository: ItemsRepository
    private let inventoryService: InventoryService
    private let slotId: String

    // MARK: - Initialization

    public init(
        game: Game,
        gameRepository: GameSaveStorage,
        itemsRepository: ItemsRepository,
        inventoryService: InventoryService,
        slotId: String = SaveSlotInfo.defaultSlotId,
        playTime: TimeInterval = 0
    ) {
        self.game = game
        self.gameSnapshot = OSAllocatedUnfairLock(initialState: game)
        self.gameRepository = gameRepository
        self.itemsRepository = itemsRepository
        self.inventoryService = inventoryService
        self.slotId = slotId
        self.playTime = playTime
    }

    // MARK: - Day Management

    public func advanceToNextDay() {
        let currentDayNumber = game.gameState.currentDay.dayNumber
        let nextDayNumber = currentDayNumber + 1

        // Find next day in calendar
        guard let nextDayIndex = game.gameState.calendar.firstIndex(where: { $0.dayNumber == nextDayNumber }) else {
            return // No more days in calendar (game finished)
        }

        game.gameState.currentDay = game.gameState.calendar[nextDayIndex]

        // Restore action points for new day
        restoreActionPoints()
    }

    public func spendActionPoints(_ amount: Int) {
        if case .success(let newPoints) = game.gameState.actionPoints.spend(amount) {
            game.gameState.actionPoints = newPoints
        }
    }

    private func restoreActionPoints() {
        game.gameState.actionPoints = game.gameState.actionPoints.reset()
    }

    // MARK: - Player Progression

    public func addPlayerExperience(_ amount: Int) {
        // Simply add XP - level is computed automatically (TDD: single source of truth)
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

    public func addDropsToPlayerInventory(rewards: HuntRewards) async {
        // Add materials (stackable)
        for material in rewards.materials {
            player.inventory = inventoryService.addMaterial(
                id: material.id,
                quantity: material.amount,
                to: player.inventory
            )
        }

        // Add weapon if dropped
        if let weaponIdString = rewards.weaponId,
           let weaponId = UUID(uuidString: weaponIdString),
           let weaponItem = await itemsRepository.getHeroItem(weaponId) as? WeaponItem {
            let weapon = ElfWeaponItem(weaponItem: weaponItem)
            player.inventory = inventoryService.addWeapon(weapon, to: player.inventory)
        }

        // Add armor if dropped
        if let armorIdString = rewards.armorId,
           let armorId = UUID(uuidString: armorIdString),
           let defenseItem = await itemsRepository.getHeroItem(armorId) as? DefenseItem {
            let armor = ElfDefenseItem(defenseItem: defenseItem)
            player.inventory = inventoryService.addArmor(armor, to: player.inventory)
        }
    }

    public func addFishToInventory(_ fish: [Fish]) {
        for f in fish {
            player.inventory = inventoryService.addMaterial(
                id: f.id.rawValue,
                quantity: 1,
                to: player.inventory
            )
        }
    }

    public func addHerbsToInventory(_ herbs: [Herb]) {
        for herb in herbs {
            player.inventory = inventoryService.addMaterial(
                id: herb.id.rawValue,
                quantity: 1,
                to: player.inventory
            )
        }
    }

    public func addOresToInventory(_ ores: [Ore]) {
        for ore in ores {
            player.inventory = inventoryService.addMaterial(
                id: ore.id.rawValue,
                quantity: 1,
                to: player.inventory
            )
        }
    }

    // MARK: - Player Equipment

    public func setWeaponConfiguration(_ config: WeaponConfiguration) {
        player.equipped.weapons = config
    }

    public func equipArmor(_ armor: ElfDefenseItem?, slot: ArmorSlot) {
        switch slot {
        case .helmet:
            player.equipped.helmet = armor
        case .gloves:
            player.equipped.gloves = armor
        case .shoes:
            player.equipped.shoes = armor
        case .upperBody:
            player.equipped.upperBody = armor
        case .bottomBody:
            player.equipped.bottomBody = armor
        }
    }

    public func equipJewelry(_ jewelry: ElfJewelryItem?, slot: JewelrySlot) {
        switch slot {
        case .ring:
            player.equipped.ring = jewelry
        case .necklace:
            player.equipped.necklace = jewelry
        case .earrings:
            player.equipped.earrings = jewelry
        }
    }

    public func equipShirt(_ shirt: ElfRobeItem?) {
        player.equipped.shirt = shirt
    }

    public func applyCraftResult(_ inventory: ElfInventory) {
        player.inventory = inventory
    }

    // MARK: - Persistence

    public func saveGame() async throws {
        try await gameRepository.save(game, slotId: slotId, playTime: playTime)
    }
}

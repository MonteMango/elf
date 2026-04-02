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
// TODO: [P1] - @preconcurrency suppresses strict concurrency checks for GameService conformance.
// This allows implementing async protocol requirements without async keyword.
// Fix: Remove @preconcurrency and ensure all protocol methods match their async signatures.
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
            // TODO: [P1] - AsyncStream continuation cleanup: onTermination is a synchronous callback but wraps
            // removal in an unstructured Task. If actor is deallocated before Task completes, continuation
            // remains in dictionary (memory leak). Fix: Use Task.detached for cleanup.
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

    // TODO: [P2] - Double didSet trigger: modifying game.gameState.currentDay then calling restoreActionPoints()
    // triggers didSet twice — two Equatable comparisons, two broadcasts to subscribers.
    // Subscribers receive intermediate state. Fix: Group mutations into a single operation.
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

    // TODO: [P0] - Reentrancy: suspension points (await itemsRepository.getHeroItem) between inventory mutations.
    // Another actor method can modify player.inventory during suspension, causing materials added before
    // the suspension to be lost. Fix: Fetch all items upfront, then apply all mutations without suspension.
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

    // MARK: - Atomic Player Modification

    /// Atomically reads and modifies player state within actor isolation.
    /// Guarantees no state changes between read and write (no suspension points).
    public func modifyPlayer(_ transform: @Sendable (inout ElfInfo) -> Void) {
        transform(&game.houses[game.playerHouseIndex].members[game.playerMemberIndex])
    }

    // MARK: - Persistence

    public func saveGame() async throws {
        try await gameRepository.save(game, slotId: slotId, playTime: playTime)
    }
}

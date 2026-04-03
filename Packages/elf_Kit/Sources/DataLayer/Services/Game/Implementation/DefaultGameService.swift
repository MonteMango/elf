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
public actor DefaultGameService: GameService {

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
                Task.detached { [weak self] in
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
    private let inventoryService: InventoryService
    private let slotId: String

    // MARK: - Initialization

    public init(
        game: Game,
        gameRepository: GameSaveStorage,
        inventoryService: InventoryService,
        slotId: String = SaveSlotInfo.defaultSlotId,
        playTime: TimeInterval = 0
    ) {
        self.game = game
        self.gameSnapshot = OSAllocatedUnfairLock(initialState: game)
        self.gameRepository = gameRepository
        self.inventoryService = inventoryService
        self.slotId = slotId
        self.playTime = playTime
    }

    // MARK: - Day Management

    public func advanceToNextDay() {
        let currentDayNumber = game.gameState.currentDay.dayNumber
        let nextDayNumber = currentDayNumber + 1

        guard let nextDayIndex = game.gameState.calendar.firstIndex(where: { $0.dayNumber == nextDayNumber }) else {
            return // No more days in calendar (game finished)
        }

        // Single mutation — didSet fires once with consistent state
        var updatedState = game.gameState
        updatedState.currentDay = updatedState.calendar[nextDayIndex]
        updatedState.actionPoints = updatedState.actionPoints.reset()
        game.gameState = updatedState
    }

    public func spendActionPoints(_ amount: Int) {
        if case .success(let newPoints) = game.gameState.actionPoints.spend(amount) {
            game.gameState.actionPoints = newPoints
        }
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

    // TODO: [P3] - Multiple didSet triggers: each player.inventory assignment in the loop triggers
    // game didSet — Equatable comparison + broadcast per iteration. With many drops this is wasteful.
    // Intermediate states are valid but unnecessary. Fix: Accumulate into local inventory copy,
    // assign once (same pattern as advanceToNextDay).
    public func addDropsToPlayerInventory(rewards: HuntRewards) {
        for material in rewards.materials {
            player.inventory = inventoryService.addMaterial(
                id: material.id,
                quantity: material.amount,
                to: player.inventory
            )
        }

        if let weapon = rewards.weapon {
            player.inventory = inventoryService.addWeapon(weapon, to: player.inventory)
        }

        if let armor = rewards.armor {
            player.inventory = inventoryService.addArmor(armor, to: player.inventory)
        }
    }

    // TODO: [P3] - Multiple didSet triggers: same pattern as addDropsToPlayerInventory.
    // Each loop iteration triggers game didSet. Fix: Batch into single inventory assignment.
    public func addFishToInventory(_ fish: [Fish]) {
        for f in fish {
            player.inventory = inventoryService.addMaterial(
                id: f.id.rawValue,
                quantity: 1,
                to: player.inventory
            )
        }
    }

    // TODO: [P3] - Multiple didSet triggers: same pattern as addDropsToPlayerInventory.
    public func addHerbsToInventory(_ herbs: [Herb]) {
        for herb in herbs {
            player.inventory = inventoryService.addMaterial(
                id: herb.id.rawValue,
                quantity: 1,
                to: player.inventory
            )
        }
    }

    // TODO: [P3] - Multiple didSet triggers: same pattern as addDropsToPlayerInventory.
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

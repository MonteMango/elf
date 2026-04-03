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
    private let debugGameLogger: DebugGameLogger
    private let slotId: String

    // MARK: - Initialization

    public init(
        game: Game,
        gameRepository: GameSaveStorage,
        inventoryService: InventoryService,
        debugGameLogger: DebugGameLogger,
        slotId: String = SaveSlotInfo.defaultSlotId,
        playTime: TimeInterval = 0
    ) {
        self.game = game
        self.gameSnapshot = OSAllocatedUnfairLock(initialState: game)
        self.gameRepository = gameRepository
        self.inventoryService = inventoryService
        self.debugGameLogger = debugGameLogger
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

    // MARK: - Atomic Player Modification

    /// Atomically reads and modifies player state within actor isolation.
    /// Guarantees no state changes between read and write (no suspension points).
    public func modifyPlayer(_ transform: @Sendable (inout ElfInfo) -> Void) {
        transform(&game.houses[game.playerHouseIndex].members[game.playerMemberIndex])
    }

    // MARK: - Persistence

    public func saveGame() async throws {
        debugGameLogger.logGameSave(game: game, playTime: playTime)
        try await gameRepository.save(game, slotId: slotId, playTime: playTime)
    }
}

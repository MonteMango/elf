//
//  DefaultGameService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import Foundation

/// Default implementation of GameService
/// Uses AsyncStream to broadcast game state changes to subscribers
@MainActor
public final class DefaultGameService: GameService {

    // MARK: - Properties

    public private(set) var game: Game {
        didSet {
            guard game != oldValue else { return }
            for continuation in continuations.values {
                continuation.yield(game)
            }
        }
    }

    public private(set) var playTime: TimeInterval

    // MARK: - Stream

    private var continuations: [UUID: AsyncStream<Game>.Continuation] = [:]

    public func gameUpdates() -> AsyncStream<Game> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
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

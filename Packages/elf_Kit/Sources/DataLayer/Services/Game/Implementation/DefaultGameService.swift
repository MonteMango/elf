//
//  DefaultGameService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import Foundation

/// Default implementation of GameService
/// Uses @Observable for SwiftUI integration and @MainActor for thread safety
@Observable
@MainActor
public final class DefaultGameService: GameService {

    // MARK: - Properties

    public private(set) var game: Game
    public private(set) var playTime: TimeInterval

    // MARK: - Player Access

    private var player: ElfInfo {
        get { game.houses[game.playerHouseIndex].members[game.playerMemberIndex] }
        set { game.houses[game.playerHouseIndex].members[game.playerMemberIndex] = newValue }
    }

    // MARK: - Dependencies

    private let gameRepository: GameRepository?
    private let itemsRepository: ItemsRepository?
    private let slotId: String

    // MARK: - Initialization

    public init(
        game: Game,
        gameRepository: GameRepository? = nil,
        itemsRepository: ItemsRepository? = nil,
        slotId: String = SaveSlotInfo.defaultSlotId,
        playTime: TimeInterval = 0
    ) {
        self.game = game
        self.gameRepository = gameRepository
        self.itemsRepository = itemsRepository
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

    public func restoreActionPoints() {
        game.gameState.actionPoints = game.gameState.actionPoints.reset()
    }

    // MARK: - Player Progression

    public func addPlayerExperience(_ amount: Int) {
        addElfExperience(
            houseIndex: game.playerHouseIndex,
            memberIndex: game.playerMemberIndex,
            amount: amount
        )
    }

    public func addDropsToPlayerInventory(rewards: HuntRewards) {
        // Add materials (stackable)
        for material in rewards.materials {
            player.inventory.addMaterial(id: material.id, quantity: material.amount)
        }

        // Add weapon if dropped
        if let weaponIdString = rewards.weaponId,
           let weaponId = UUID(uuidString: weaponIdString),
           let weaponItem = itemsRepository?.getHeroItem(weaponId) as? WeaponItem {
            let weapon = ElfWeaponItem(weaponItem: weaponItem)
            player.inventory.addWeapon(weapon)
        }

        // Add armor if dropped
        if let armorIdString = rewards.armorId,
           let armorId = UUID(uuidString: armorIdString),
           let defenseItem = itemsRepository?.getHeroItem(armorId) as? DefenseItem {
            let armor = ElfDefenseItem(defenseItem: defenseItem)
            player.inventory.addArmor(armor)
        }
    }

    // MARK: - Player HP Management

    public func healPlayer(_ amount: Int16) {
        healElf(
            houseIndex: game.playerHouseIndex,
            memberIndex: game.playerMemberIndex,
            amount: amount
        )
    }

    public func damagePlayer(_ amount: Int16) {
        damageElf(
            houseIndex: game.playerHouseIndex,
            memberIndex: game.playerMemberIndex,
            amount: amount
        )
    }

    public func restorePlayerFullHP() {
        player.currentHP = player.maxHP
    }

    // MARK: - Player MP Management

    public func restorePlayerMP(_ amount: Int16) {
        let newMP = player.currentMP + amount
        player.currentMP = min(newMP, player.maxMP)
    }

    public func consumePlayerMP(_ amount: Int16) {
        player.currentMP = max(0, player.currentMP - amount)
    }

    public func restorePlayerFullMP() {
        player.currentMP = player.maxMP
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

    // MARK: - House Management

    public func swapElves(
        house1Index: Int, member1Index: Int,
        house2Index: Int, member2Index: Int
    ) {
        // Validate indices
        guard house1Index >= 0 && house1Index < Game.housesCount,
              house2Index >= 0 && house2Index < Game.housesCount,
              member1Index >= 0 && member1Index < House.membersCount,
              member2Index >= 0 && member2Index < House.membersCount else {
            return
        }

        // Perform swap
        let temp = game.houses[house1Index].members[member1Index]
        game.houses[house1Index].members[member1Index] = game.houses[house2Index].members[member2Index]
        game.houses[house2Index].members[member2Index] = temp

        // Update player indices if player was swapped
        if house1Index == game.playerHouseIndex && member1Index == game.playerMemberIndex {
            game.playerHouseIndex = house2Index
            game.playerMemberIndex = member2Index
        } else if house2Index == game.playerHouseIndex && member2Index == game.playerMemberIndex {
            game.playerHouseIndex = house1Index
            game.playerMemberIndex = member1Index
        }
    }

    public func eliminateHouse(_ houseIndex: Int) {
        guard houseIndex >= 0 && houseIndex < Game.housesCount else { return }
        game.houses[houseIndex].isEliminated = true
    }

    // MARK: - Elf Management (Any Elf)

    public func healElf(houseIndex: Int, memberIndex: Int, amount: Int16) {
        guard houseIndex >= 0 && houseIndex < Game.housesCount,
              memberIndex >= 0 && memberIndex < House.membersCount else { return }

        let newHP = game.houses[houseIndex].members[memberIndex].currentHP + amount
        let maxHP = game.houses[houseIndex].members[memberIndex].maxHP
        game.houses[houseIndex].members[memberIndex].currentHP = min(newHP, maxHP)
    }

    public func damageElf(houseIndex: Int, memberIndex: Int, amount: Int16) {
        guard houseIndex >= 0 && houseIndex < Game.housesCount,
              memberIndex >= 0 && memberIndex < House.membersCount else { return }

        game.houses[houseIndex].members[memberIndex].currentHP =
            max(0, game.houses[houseIndex].members[memberIndex].currentHP - amount)
    }

    public func addElfExperience(houseIndex: Int, memberIndex: Int, amount: Int) {
        guard houseIndex >= 0 && houseIndex < Game.housesCount,
              memberIndex >= 0 && memberIndex < House.membersCount else { return }

        // Simply add XP - level is computed automatically (TDD: single source of truth)
        game.houses[houseIndex].members[memberIndex].currentExp += amount
    }

    // MARK: - Persistence

    public func saveGame() async throws {
        guard let repository = gameRepository else { return }
        try await repository.save(game, slotId: slotId, playTime: playTime)
    }

    public func updatePlayTime(_ time: TimeInterval) {
        playTime = time
    }
}

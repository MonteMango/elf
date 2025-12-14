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
        game.gameState.currentActionPoints = max(0, game.gameState.currentActionPoints - amount)
    }

    public func restoreActionPoints() {
        game.gameState.currentActionPoints = game.gameState.maxActionPoints
    }

    // MARK: - Player Progression

    public func addPlayerExperience(_ amount: Int) {
        addElfExperience(
            houseIndex: game.playerHouseIndex,
            memberIndex: game.playerMemberIndex,
            amount: amount
        )
    }

    public func levelUpPlayer() {
        let houseIndex = game.playerHouseIndex
        let memberIndex = game.playerMemberIndex

        guard game.houses[houseIndex].members[memberIndex].currentExp >=
              game.houses[houseIndex].members[memberIndex].expToNextLevel else { return }

        game.houses[houseIndex].members[memberIndex].currentExp -=
            game.houses[houseIndex].members[memberIndex].expToNextLevel
        game.houses[houseIndex].members[memberIndex].level += 1

        // Increase exp required for next level (simple scaling)
        game.houses[houseIndex].members[memberIndex].expToNextLevel =
            Int(Double(game.houses[houseIndex].members[memberIndex].expToNextLevel) * 1.2)

        // TODO: Add random attribute bonuses on level up via AttributeRandomizer
    }

    public func addDropsToPlayerInventory(rewards: HuntRewards) {
        let houseIndex = game.playerHouseIndex
        let memberIndex = game.playerMemberIndex

        // Add materials (stackable)
        for material in rewards.materials {
            game.houses[houseIndex].members[memberIndex]
                .inventory.addMaterial(id: material.id, quantity: material.amount)
        }

        // Add weapon if dropped
        if let weaponIdString = rewards.weaponId,
           let weaponId = UUID(uuidString: weaponIdString),
           let weaponItem = itemsRepository?.getHeroItem(weaponId) as? WeaponItem {
            let weapon = ElfWeaponItem(weaponItem: weaponItem)
            game.houses[houseIndex].members[memberIndex]
                .inventory.addWeapon(weapon)
        }

        // Add armor if dropped
        if let armorIdString = rewards.armorId,
           let armorId = UUID(uuidString: armorIdString),
           let defenseItem = itemsRepository?.getHeroItem(armorId) as? DefenseItem {
            let armor = ElfDefenseItem(defenseItem: defenseItem)
            game.houses[houseIndex].members[memberIndex]
                .inventory.addArmor(armor)
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
        let houseIndex = game.playerHouseIndex
        let memberIndex = game.playerMemberIndex
        game.houses[houseIndex].members[memberIndex].currentHP =
            game.houses[houseIndex].members[memberIndex].maxHP
    }

    // MARK: - Player MP Management

    public func restorePlayerMP(_ amount: Int16) {
        let houseIndex = game.playerHouseIndex
        let memberIndex = game.playerMemberIndex
        let newMP = game.houses[houseIndex].members[memberIndex].currentMP + amount
        let maxMP = game.houses[houseIndex].members[memberIndex].maxMP
        game.houses[houseIndex].members[memberIndex].currentMP = min(newMP, maxMP)
    }

    public func consumePlayerMP(_ amount: Int16) {
        let houseIndex = game.playerHouseIndex
        let memberIndex = game.playerMemberIndex
        game.houses[houseIndex].members[memberIndex].currentMP =
            max(0, game.houses[houseIndex].members[memberIndex].currentMP - amount)
    }

    public func restorePlayerFullMP() {
        let houseIndex = game.playerHouseIndex
        let memberIndex = game.playerMemberIndex
        game.houses[houseIndex].members[memberIndex].currentMP =
            game.houses[houseIndex].members[memberIndex].maxMP
    }

    // MARK: - Player Equipment

    public func equipWeapon(_ weapon: ElfWeaponItem?) {
        game.houses[game.playerHouseIndex].members[game.playerMemberIndex].equippedWeapon = weapon
    }

    public func equipShield(_ shield: ElfShieldItem?) {
        game.houses[game.playerHouseIndex].members[game.playerMemberIndex].equippedShield = shield
    }

    public func equipHelmet(_ helmet: ElfDefenseItem?) {
        game.houses[game.playerHouseIndex].members[game.playerMemberIndex].equippedHelmet = helmet
    }

    public func equipGloves(_ gloves: ElfDefenseItem?) {
        game.houses[game.playerHouseIndex].members[game.playerMemberIndex].equippedGloves = gloves
    }

    public func equipShoes(_ shoes: ElfDefenseItem?) {
        game.houses[game.playerHouseIndex].members[game.playerMemberIndex].equippedShoes = shoes
    }

    public func equipUpperBody(_ upperBody: ElfDefenseItem?) {
        game.houses[game.playerHouseIndex].members[game.playerMemberIndex].equippedUpperBody = upperBody
    }

    public func equipBottomBody(_ bottomBody: ElfDefenseItem?) {
        game.houses[game.playerHouseIndex].members[game.playerMemberIndex].equippedBottomBody = bottomBody
    }

    public func equipShirt(_ shirt: ElfRobeItem?) {
        game.houses[game.playerHouseIndex].members[game.playerMemberIndex].equippedShirt = shirt
    }

    public func equipRing(_ ring: ElfJewelryItem?) {
        game.houses[game.playerHouseIndex].members[game.playerMemberIndex].equippedRing = ring
    }

    public func equipNecklace(_ necklace: ElfJewelryItem?) {
        game.houses[game.playerHouseIndex].members[game.playerMemberIndex].equippedNecklace = necklace
    }

    public func equipEarrings(_ earrings: ElfJewelryItem?) {
        game.houses[game.playerHouseIndex].members[game.playerMemberIndex].equippedEarrings = earrings
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

        game.houses[houseIndex].members[memberIndex].currentExp += amount

        // Auto level up if enough experience
        while game.houses[houseIndex].members[memberIndex].currentExp >=
              game.houses[houseIndex].members[memberIndex].expToNextLevel {

            game.houses[houseIndex].members[memberIndex].currentExp -=
                game.houses[houseIndex].members[memberIndex].expToNextLevel
            game.houses[houseIndex].members[memberIndex].level += 1

            // Increase exp required for next level
            game.houses[houseIndex].members[memberIndex].expToNextLevel =
                Int(Double(game.houses[houseIndex].members[memberIndex].expToNextLevel) * 1.2)
        }
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

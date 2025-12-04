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

    // MARK: - Initialization

    public init(game: Game) {
        self.game = game
    }

    // MARK: - Day Management

    public func advanceToNextDay() {
        guard !game.gameState.upcomingDays.isEmpty else { return }

        let nextDay = game.gameState.upcomingDays.removeFirst()
        game.gameState.currentDay = nextDay

        // Generate new upcoming day
        let newDayNumber = (game.gameState.upcomingDays.last?.dayNumber ?? nextDay.dayNumber) + 1
        let newDayType = generateDayType(for: newDayNumber)
        let newDay = GameDay(dayNumber: newDayNumber, dayType: newDayType)
        game.gameState.upcomingDays.append(newDay)

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

    public func equipPlayerItem(_ itemId: UUID, to slot: HeroItemType) {
        let houseIndex = game.playerHouseIndex
        let memberIndex = game.playerMemberIndex
        game.houses[houseIndex].members[memberIndex].equippedItems[slot] = itemId
    }

    public func unequipPlayerItem(from slot: HeroItemType) {
        let houseIndex = game.playerHouseIndex
        let memberIndex = game.playerMemberIndex
        game.houses[houseIndex].members[memberIndex].equippedItems.removeValue(forKey: slot)
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

    // MARK: - Private Helpers

    private func generateDayType(for dayNumber: Int) -> DayType {
        // Simple pattern: every 4th day is house war, every 3rd is dungeon
        if dayNumber % 4 == 0 {
            return .houseWar
        } else if dayNumber % 3 == 0 {
            return .dungeon
        } else {
            return .normal
        }
    }
}

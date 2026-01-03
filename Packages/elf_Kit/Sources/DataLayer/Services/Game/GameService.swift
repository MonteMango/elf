//
//  GameService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import Foundation

/// Protocol for managing game state
/// Provides methods for day management, player progression, HP/MP, equipment, and house operations
@MainActor
public protocol GameService: AnyObject {

    // MARK: - Game State

    /// Current game state
    var game: Game { get }

    // MARK: - Day Management

    /// Advances to the next day in the game
    func advanceToNextDay()

    /// Spends action points for an activity
    /// - Parameter amount: Number of action points to spend
    func spendActionPoints(_ amount: Int)

    /// Restores action points to maximum
    func restoreActionPoints()

    // MARK: - Player Progression

    /// Adds experience points to the player
    /// - Parameter amount: Experience points to add
    func addPlayerExperience(_ amount: Int)

    /// Levels up the player if enough experience
    func levelUpPlayer()

    /// Adds hunt rewards (drops) to player's inventory
    /// - Parameter rewards: Hunt rewards containing materials, weapon, and armor drops
    func addDropsToPlayerInventory(rewards: HuntRewards)

    // MARK: - Player HP Management

    /// Heals the player by a specified amount
    /// - Parameter amount: HP to restore (capped at maxHP)
    func healPlayer(_ amount: Int16)

    /// Damages the player by a specified amount
    /// - Parameter amount: HP to remove (minimum 0)
    func damagePlayer(_ amount: Int16)

    /// Fully restores player HP to maximum
    func restorePlayerFullHP()

    // MARK: - Player MP Management

    /// Restores player mana points
    /// - Parameter amount: MP to restore (capped at maxMP)
    func restorePlayerMP(_ amount: Int16)

    /// Consumes player mana points
    /// - Parameter amount: MP to consume (minimum 0)
    func consumePlayerMP(_ amount: Int16)

    /// Fully restores player MP to maximum
    func restorePlayerFullMP()

    // MARK: - Player Equipment

    /// Sets the weapon configuration (weapon, shield, dual-wield, etc.)
    func setWeaponConfiguration(_ config: WeaponConfiguration)

    /// Equips or unequips armor in the specified slot
    func equipArmor(_ armor: ElfDefenseItem?, slot: ArmorSlot)

    /// Equips or unequips jewelry in the specified slot
    func equipJewelry(_ jewelry: ElfJewelryItem?, slot: JewelrySlot)

    /// Equips or unequips a shirt
    func equipShirt(_ shirt: ElfRobeItem?)

    // MARK: - House Management

    /// Swaps two elves between houses
    /// - Parameters:
    ///   - house1Index: Index of first house (0-7)
    ///   - member1Index: Index of member in first house (0-9)
    ///   - house2Index: Index of second house (0-7)
    ///   - member2Index: Index of member in second house (0-9)
    func swapElves(
        house1Index: Int, member1Index: Int,
        house2Index: Int, member2Index: Int
    )

    /// Marks a house as eliminated
    /// - Parameter houseIndex: Index of the house to eliminate (0-7)
    func eliminateHouse(_ houseIndex: Int)

    // MARK: - Elf Management (Any Elf)

    /// Heals a specific elf
    /// - Parameters:
    ///   - houseIndex: Index of the house (0-7)
    ///   - memberIndex: Index of the member (0-9)
    ///   - amount: HP to restore
    func healElf(houseIndex: Int, memberIndex: Int, amount: Int16)

    /// Damages a specific elf
    /// - Parameters:
    ///   - houseIndex: Index of the house (0-7)
    ///   - memberIndex: Index of the member (0-9)
    ///   - amount: HP to remove
    func damageElf(houseIndex: Int, memberIndex: Int, amount: Int16)

    /// Adds experience to a specific elf
    /// - Parameters:
    ///   - houseIndex: Index of the house (0-7)
    ///   - memberIndex: Index of the member (0-9)
    ///   - amount: Experience to add
    func addElfExperience(houseIndex: Int, memberIndex: Int, amount: Int)

    // MARK: - Persistence

    /// Saves the current game state
    func saveGame() async throws

    /// Current play time in seconds
    var playTime: TimeInterval { get }

    /// Updates play time
    func updatePlayTime(_ time: TimeInterval)
}

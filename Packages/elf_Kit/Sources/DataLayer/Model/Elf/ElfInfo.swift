//
//  ElfInfo.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.12.25.
//

import Foundation

/// Information about an elf (player or AI)
/// Used as member of a House
public struct ElfInfo: Sendable, Equatable, Identifiable {

    // MARK: - Identity

    public let id: UUID

    // MARK: - Basic Info

    public var name: String
    public var imageName: String
    public var fightStyle: FightStyle

    // MARK: - Progression

    public var level: Int16
    public var currentExp: Int
    public var expToNextLevel: Int

    // MARK: - Attributes

    public var fightStyleAttributes: HeroAttributes
    public var randomLevelAttributes: HeroAttributes

    // MARK: - Current Stats

    public var currentHP: Int16
    public var currentMP: Int16

    // MARK: - Equipment

    public var equipped: EquippedItems

    // MARK: - Inventory

    public var inventory: ElfInventory

    // MARK: - Reputation

    public var reputation: Int

    // MARK: - Computed Properties

    public var totalAttributes: HeroAttributes {
        HeroAttributes(
            hitPoints: fightStyleAttributes.hitPoints + randomLevelAttributes.hitPoints,
            manaPoints: fightStyleAttributes.manaPoints + randomLevelAttributes.manaPoints,
            agility: fightStyleAttributes.agility + randomLevelAttributes.agility,
            strength: fightStyleAttributes.strength + randomLevelAttributes.strength,
            power: fightStyleAttributes.power + randomLevelAttributes.power,
            instinct: fightStyleAttributes.instinct + randomLevelAttributes.instinct
        )
    }

    public var maxHP: Int16 {
        totalAttributes.hitPoints
    }

    public var maxMP: Int16 {
        totalAttributes.manaPoints
    }

    public var expProgress: Double {
        guard expToNextLevel > 0 else { return 0 }
        return Double(currentExp) / Double(expToNextLevel)
    }

    public var hpProgress: Double {
        guard maxHP > 0 else { return 0 }
        return Double(currentHP) / Double(maxHP)
    }

    public var mpProgress: Double {
        guard maxMP > 0 else { return 0 }
        return Double(currentMP) / Double(maxMP)
    }

    /// Get equipped item ID for a slot (for UI compatibility)
    /// Returns the base item ID (from JSON) for image lookup and repository queries
    public func equippedItemId(for slot: HeroItemType) -> UUID? {
        equipped.equippedBaseItemId(for: slot)
    }

    /// Get all equipped item IDs as dictionary (for UI compatibility)
    /// Returns base item IDs (from JSON) for image lookup and repository queries
    public var equippedItemIds: [HeroItemType: UUID] {
        equipped.equippedBaseItemIds
    }

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        name: String,
        imageName: String,
        fightStyle: FightStyle,
        level: Int16,
        currentExp: Int,
        expToNextLevel: Int,
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes,
        currentHP: Int16,
        currentMP: Int16,
        equipped: EquippedItems,
        inventory: ElfInventory = ElfInventory(),
        reputation: Int = 0
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.fightStyle = fightStyle
        self.level = level
        self.currentExp = currentExp
        self.expToNextLevel = expToNextLevel
        self.fightStyleAttributes = fightStyleAttributes
        self.randomLevelAttributes = randomLevelAttributes
        self.currentHP = currentHP
        self.currentMP = currentMP
        self.equipped = equipped
        self.inventory = inventory
        self.reputation = reputation
    }

}

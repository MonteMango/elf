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

    public var currentExp: Int

    // MARK: - Farming Skills (TDD: stored XP, levels computed)

    public var foragingExp: Int
    public var fishingExp: Int
    public var miningExp: Int

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
        totalAttributes.hitPoints.value
    }

    public var maxMP: Int16 {
        totalAttributes.manaPoints.value
    }

    /// Level computed from currentExp (TDD: single source of truth)
    /// Formula: level = max(1, min(12, currentExp / 100))
    public var level: Int {
        max(1, min(12, currentExp / 100))
    }

    /// XP threshold to reach next level
    public var expToNextLevel: Int {
        guard level < 12 else { return 0 }
        return (level + 1) * 100
    }

    /// Progress within current level (0.0 to 1.0)
    public var expProgress: Double {
        guard level < 12 else { return 1.0 }
        let levelStartXP = level == 1 ? 0 : level * 100
        let levelEndXP = (level + 1) * 100
        let xpInLevel = currentExp - levelStartXP
        let levelSize = levelEndXP - levelStartXP
        return Double(xpInLevel) / Double(levelSize)
    }

    // MARK: - Farming Skill Levels (TDD: computed from XP)

    /// Foraging skill level (1-12), computed from foragingExp
    /// Formula: level = max(1, min(12, foragingExp / 50))
    public var foragingLevel: Int {
        max(1, min(12, foragingExp / 50))
    }

    /// Fishing skill level (1-12), computed from fishingExp
    public var fishingLevel: Int {
        max(1, min(12, fishingExp / 50))
    }

    /// Mining skill level (1-12), computed from miningExp
    public var miningLevel: Int {
        max(1, min(12, miningExp / 50))
    }

    /// Progress within current foraging level (0.0 to 1.0)
    public var foragingProgress: Double {
        farmingSkillProgress(for: foragingExp, level: foragingLevel)
    }

    /// Progress within current fishing level (0.0 to 1.0)
    public var fishingProgress: Double {
        farmingSkillProgress(for: fishingExp, level: fishingLevel)
    }

    /// Progress within current mining level (0.0 to 1.0)
    public var miningProgress: Double {
        farmingSkillProgress(for: miningExp, level: miningLevel)
    }

    /// Helper to calculate progress within a farming skill level
    private func farmingSkillProgress(for exp: Int, level: Int) -> Double {
        guard level < 12 else { return 1.0 }
        let levelStartXP = level == 1 ? 0 : level * 50
        let levelEndXP = (level + 1) * 50
        let xpInLevel = exp - levelStartXP
        let levelSize = levelEndXP - levelStartXP
        return Double(xpInLevel) / Double(levelSize)
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
        currentExp: Int,
        foragingExp: Int = 0,
        fishingExp: Int = 0,
        miningExp: Int = 0,
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
        self.currentExp = currentExp
        self.foragingExp = foragingExp
        self.fishingExp = fishingExp
        self.miningExp = miningExp
        self.fightStyleAttributes = fightStyleAttributes
        self.randomLevelAttributes = randomLevelAttributes
        self.currentHP = currentHP
        self.currentMP = currentMP
        self.equipped = equipped
        self.inventory = inventory
        self.reputation = reputation
    }

}

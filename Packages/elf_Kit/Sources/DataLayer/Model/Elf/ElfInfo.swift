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

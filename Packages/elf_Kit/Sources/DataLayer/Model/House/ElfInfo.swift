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

    // MARK: - Equipment Slots

    public var equippedWeapon: ElfWeaponItem?
    public var equippedShield: ElfShieldItem?
    public var equippedHelmet: ElfDefenseItem?
    public var equippedGloves: ElfDefenseItem?
    public var equippedShoes: ElfDefenseItem?
    public var equippedUpperBody: ElfDefenseItem?
    public var equippedBottomBody: ElfDefenseItem?
    public var equippedShirt: ElfRobeItem?
    public var equippedRing: ElfJewelryItem?
    public var equippedNecklace: ElfJewelryItem?
    public var equippedEarrings: ElfJewelryItem?

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
    public func equippedItemId(for slot: HeroItemType) -> UUID? {
        switch slot {
        case .weapons: return equippedWeapon?.id
        case .shields: return equippedShield?.id
        case .helmet: return equippedHelmet?.id
        case .gloves: return equippedGloves?.id
        case .shoes: return equippedShoes?.id
        case .upperBody: return equippedUpperBody?.id
        case .bottomBody: return equippedBottomBody?.id
        case .shirt: return equippedShirt?.id
        case .ring: return equippedRing?.id
        case .necklace: return equippedNecklace?.id
        case .earrings: return equippedEarrings?.id
        }
    }

    /// Get all equipped item IDs as dictionary (for UI compatibility)
    public var equippedItemIds: [HeroItemType: UUID] {
        var result: [HeroItemType: UUID] = [:]
        if let id = equippedWeapon?.id { result[.weapons] = id }
        if let id = equippedShield?.id { result[.shields] = id }
        if let id = equippedHelmet?.id { result[.helmet] = id }
        if let id = equippedGloves?.id { result[.gloves] = id }
        if let id = equippedShoes?.id { result[.shoes] = id }
        if let id = equippedUpperBody?.id { result[.upperBody] = id }
        if let id = equippedBottomBody?.id { result[.bottomBody] = id }
        if let id = equippedShirt?.id { result[.shirt] = id }
        if let id = equippedRing?.id { result[.ring] = id }
        if let id = equippedNecklace?.id { result[.necklace] = id }
        if let id = equippedEarrings?.id { result[.earrings] = id }
        return result
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
        equippedWeapon: ElfWeaponItem? = nil,
        equippedShield: ElfShieldItem? = nil,
        equippedHelmet: ElfDefenseItem? = nil,
        equippedGloves: ElfDefenseItem? = nil,
        equippedShoes: ElfDefenseItem? = nil,
        equippedUpperBody: ElfDefenseItem? = nil,
        equippedBottomBody: ElfDefenseItem? = nil,
        equippedShirt: ElfRobeItem? = nil,
        equippedRing: ElfJewelryItem? = nil,
        equippedNecklace: ElfJewelryItem? = nil,
        equippedEarrings: ElfJewelryItem? = nil,
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
        self.equippedWeapon = equippedWeapon
        self.equippedShield = equippedShield
        self.equippedHelmet = equippedHelmet
        self.equippedGloves = equippedGloves
        self.equippedShoes = equippedShoes
        self.equippedUpperBody = equippedUpperBody
        self.equippedBottomBody = equippedBottomBody
        self.equippedShirt = equippedShirt
        self.equippedRing = equippedRing
        self.equippedNecklace = equippedNecklace
        self.equippedEarrings = equippedEarrings
        self.inventory = inventory
        self.reputation = reputation
    }

}

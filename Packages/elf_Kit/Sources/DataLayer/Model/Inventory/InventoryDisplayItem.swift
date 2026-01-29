//
//  InventoryDisplayItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Unified item representation for inventory UI display
public struct InventoryDisplayItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let imageName: String
    public let quantity: Int?
    public let isEquipped: Bool
    public let category: InventoryCategory
    public let itemDetails: ItemDetails

    public init(
        id: UUID,
        title: String,
        imageName: String,
        quantity: Int? = nil,
        isEquipped: Bool = false,
        category: InventoryCategory,
        itemDetails: ItemDetails
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.quantity = quantity
        self.isEquipped = isEquipped
        self.category = category
        self.itemDetails = itemDetails
    }
}

// MARK: - Item Details

public enum ItemDetails: Equatable, Sendable {
    case weapon(WeaponDetails)
    case armor(ArmorDetails)
    case shield(ShieldDetails)
    case jewelry(JewelryDetails)
    case material(MaterialDetails)
    case potionScroll(PotionScrollDetails)
}

// MARK: - Weapon Details

public struct WeaponDetails: Equatable, Sendable {
    public let attackMin: Int
    public let attackMax: Int
    public let attackPoints: Int
    public let handUse: String
    public let strength: Int
    public let agility: Int
    public let power: Int
    public let instinct: Int
    public let hitPoints: Int
    public let enchantLevel: Int?

    public init(
        attackMin: Int,
        attackMax: Int,
        attackPoints: Int,
        handUse: String,
        strength: Int = 0,
        agility: Int = 0,
        power: Int = 0,
        instinct: Int = 0,
        hitPoints: Int = 0,
        enchantLevel: Int? = nil
    ) {
        self.attackMin = attackMin
        self.attackMax = attackMax
        self.attackPoints = attackPoints
        self.handUse = handUse
        self.strength = strength
        self.agility = agility
        self.power = power
        self.instinct = instinct
        self.hitPoints = hitPoints
        self.enchantLevel = enchantLevel
    }
}

// MARK: - Armor Details

public struct ArmorDetails: Equatable, Sendable {
    public let defense: Int
    public let protectedParts: [String]
    public let strength: Int
    public let agility: Int
    public let power: Int
    public let instinct: Int
    public let hitPoints: Int

    public init(
        defense: Int,
        protectedParts: [String] = [],
        strength: Int = 0,
        agility: Int = 0,
        power: Int = 0,
        instinct: Int = 0,
        hitPoints: Int = 0
    ) {
        self.defense = defense
        self.protectedParts = protectedParts
        self.strength = strength
        self.agility = agility
        self.power = power
        self.instinct = instinct
        self.hitPoints = hitPoints
    }
}

// MARK: - Shield Details

public struct ShieldDetails: Equatable, Sendable {
    public let defense: Int
    public let blockPoints: Int
    public let strength: Int
    public let agility: Int
    public let hitPoints: Int

    public init(
        defense: Int,
        blockPoints: Int = 1,
        strength: Int = 0,
        agility: Int = 0,
        hitPoints: Int = 0
    ) {
        self.defense = defense
        self.blockPoints = blockPoints
        self.strength = strength
        self.agility = agility
        self.hitPoints = hitPoints
    }
}

// MARK: - Jewelry Details

public struct JewelryDetails: Equatable, Sendable {
    public let magicDefense: Int
    public let strength: Int
    public let agility: Int
    public let power: Int
    public let instinct: Int
    public let hitPoints: Int
    public let manaPoints: Int

    public init(
        magicDefense: Int = 0,
        strength: Int = 0,
        agility: Int = 0,
        power: Int = 0,
        instinct: Int = 0,
        hitPoints: Int = 0,
        manaPoints: Int = 0
    ) {
        self.magicDefense = magicDefense
        self.strength = strength
        self.agility = agility
        self.power = power
        self.instinct = instinct
        self.hitPoints = hitPoints
        self.manaPoints = manaPoints
    }
}

// MARK: - Material Details

public struct MaterialDetails: Equatable, Sendable {
    public let description: String
    public let stackSize: Int
    public let subcategory: MaterialSubcategory

    public init(
        description: String,
        stackSize: Int = 99,
        subcategory: MaterialSubcategory = .monsters
    ) {
        self.description = description
        self.stackSize = stackSize
        self.subcategory = subcategory
    }
}

// MARK: - Potion/Scroll Details (placeholder)

public struct PotionScrollDetails: Equatable, Sendable {
    public let effect: String
    public let duration: Int?

    public init(effect: String, duration: Int? = nil) {
        self.effect = effect
        self.duration = duration
    }
}

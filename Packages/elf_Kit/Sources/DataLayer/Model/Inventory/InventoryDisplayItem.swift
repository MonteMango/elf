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

    public var descriptionLines: [String] {
        switch self {
        case .weapon(let details):
            return details.descriptionLines
        case .armor(let details):
            return details.descriptionLines
        case .shield(let details):
            return details.descriptionLines
        case .jewelry(let details):
            return details.descriptionLines
        case .material(let details):
            return details.descriptionLines
        case .potionScroll(let details):
            return details.descriptionLines
        }
    }
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

    public var descriptionLines: [String] {
        var lines: [String] = []
        lines.append("Attack: \(attackMin)-\(attackMax)")
        lines.append("Attack points: \(attackPoints)")
        lines.append("Hands use: \(handUse)")
        lines.append("")
        if strength > 0 { lines.append("Strength: \(strength)") }
        if agility > 0 { lines.append("Agility: \(agility)") }
        if power > 0 { lines.append("Power: \(power)") }
        if instinct > 0 { lines.append("Instinct: \(instinct)") }
        if hitPoints > 0 { lines.append("HP: \(hitPoints)") }
        if let enchant = enchantLevel, enchant > 0 {
            lines.append("Enchant: +\(enchant)")
        }
        return lines
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

    public var descriptionLines: [String] {
        var lines: [String] = []
        lines.append("Defense: \(defense)")
        if !protectedParts.isEmpty {
            lines.append("Protects: \(protectedParts.joined(separator: ", "))")
        }
        lines.append("")
        if strength > 0 { lines.append("Strength: \(strength)") }
        if agility > 0 { lines.append("Agility: \(agility)") }
        if power > 0 { lines.append("Power: \(power)") }
        if instinct > 0 { lines.append("Instinct: \(instinct)") }
        if hitPoints > 0 { lines.append("HP: \(hitPoints)") }
        return lines
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

    public var descriptionLines: [String] {
        var lines: [String] = []
        lines.append("Defense: \(defense)")
        lines.append("Block points: +\(blockPoints)")
        lines.append("")
        if strength > 0 { lines.append("Strength: \(strength)") }
        if agility > 0 { lines.append("Agility: \(agility)") }
        if hitPoints > 0 { lines.append("HP: \(hitPoints)") }
        return lines
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

    public var descriptionLines: [String] {
        var lines: [String] = []
        if magicDefense > 0 { lines.append("Magic defense: \(magicDefense)") }
        lines.append("")
        if strength > 0 { lines.append("Strength: \(strength)") }
        if agility > 0 { lines.append("Agility: \(agility)") }
        if power > 0 { lines.append("Power: \(power)") }
        if instinct > 0 { lines.append("Instinct: \(instinct)") }
        if hitPoints > 0 { lines.append("HP: \(hitPoints)") }
        if manaPoints > 0 { lines.append("MP: \(manaPoints)") }
        return lines
    }
}

// MARK: - Material Details

public struct MaterialDetails: Equatable, Sendable {
    public let description: String
    public let stackSize: Int

    public init(description: String, stackSize: Int = 99) {
        self.description = description
        self.stackSize = stackSize
    }

    public var descriptionLines: [String] {
        [description]
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

    public var descriptionLines: [String] {
        var lines = [effect]
        if let dur = duration {
            lines.append("Duration: \(dur) turns")
        }
        return lines
    }
}

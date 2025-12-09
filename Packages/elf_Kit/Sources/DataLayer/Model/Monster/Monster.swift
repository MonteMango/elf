//
//  Monster.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

// MARK: - Monster

public struct Monster: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let imageName: String

    // XP Reward
    public let expReward: [ChanceAmount]

    // Combat stats
    public let minimumAttack: Int
    public let maximumAttack: Int
    public let attackPoints: Int
    public let defensePoints: Int
    public let hitPoints: Int
    public let manaPoints: Int

    // Attributes
    public let strength: Int
    public let agility: Int
    public let power: Int
    public let intuition: Int

    // Armor per body part
    public let partsProtection: PartsProtection

    // Drops
    public let drops: MonsterDrops

    public init(
        id: UUID,
        title: String,
        imageName: String,
        expReward: [ChanceAmount],
        minimumAttack: Int,
        maximumAttack: Int,
        attackPoints: Int,
        defensePoints: Int,
        hitPoints: Int,
        manaPoints: Int,
        strength: Int,
        agility: Int,
        power: Int,
        intuition: Int,
        partsProtection: PartsProtection,
        drops: MonsterDrops
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.expReward = expReward
        self.minimumAttack = minimumAttack
        self.maximumAttack = maximumAttack
        self.attackPoints = attackPoints
        self.defensePoints = defensePoints
        self.hitPoints = hitPoints
        self.manaPoints = manaPoints
        self.strength = strength
        self.agility = agility
        self.power = power
        self.intuition = intuition
        self.partsProtection = partsProtection
        self.drops = drops
    }
}

// MARK: - ChanceAmount

public struct ChanceAmount: Codable, Sendable, Hashable {
    public let amount: Int
    public let chance: Double

    public init(amount: Int, chance: Double) {
        self.amount = amount
        self.chance = chance
    }
}

// MARK: - PartsProtection

public struct PartsProtection: Codable, Sendable, Hashable {
    public let head: Int
    public let left: Int
    public let center: Int
    public let right: Int
    public let legs: Int

    public init(head: Int, left: Int, center: Int, right: Int, legs: Int) {
        self.head = head
        self.left = left
        self.center = center
        self.right = right
        self.legs = legs
    }
}

// MARK: - MonsterDrops

public struct MonsterDrops: Codable, Sendable, Hashable {
    public let weapons: [ItemDrop]
    public let armor: [ItemDrop]
    public let materials: [MaterialDrop]

    public init(weapons: [ItemDrop], armor: [ItemDrop], materials: [MaterialDrop]) {
        self.weapons = weapons
        self.armor = armor
        self.materials = materials
    }
}

// MARK: - ItemDrop

public struct ItemDrop: Codable, Sendable, Hashable {
    public let id: String
    public let chance: Double

    public init(id: String, chance: Double) {
        self.id = id
        self.chance = chance
    }
}

// MARK: - MaterialDrop

public struct MaterialDrop: Codable, Sendable, Hashable {
    public let id: UUID
    public let chances: [ChanceAmount]

    public init(id: UUID, chances: [ChanceAmount]) {
        self.id = id
        self.chances = chances
    }
}

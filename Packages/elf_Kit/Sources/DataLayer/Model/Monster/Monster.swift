//
//  Monster.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

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
    public let endurance: Int

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
        endurance: Int,
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
        self.endurance = endurance
        self.partsProtection = partsProtection
        self.drops = drops
    }
}

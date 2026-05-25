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
    public let defensePoints: Int
    public let hitPoints: Int
    public let manaPoints: Int

    // Attributes
    public let strength: Int
    public let agility: Int
    public let power: Int
    public let instinct: Int
    public let endurance: Int

    // Per-strike attack profiles. `rightAttack` is always present; `leftAttack`
    // is set only for monsters with two strikes per round.
    public let rightAttack: AttackProfile
    public let leftAttack: AttackProfile?

    // Armor per body part
    public let partsProtection: PartsProtection

    // Drops
    public let drops: MonsterDrops

    public init(
        id: UUID,
        title: String,
        imageName: String,
        expReward: [ChanceAmount],
        rightAttack: AttackProfile,
        leftAttack: AttackProfile? = nil,
        defensePoints: Int,
        hitPoints: Int,
        manaPoints: Int,
        strength: Int,
        agility: Int,
        power: Int,
        instinct: Int,
        endurance: Int,
        partsProtection: PartsProtection,
        drops: MonsterDrops
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.expReward = expReward
        self.rightAttack = rightAttack
        self.leftAttack = leftAttack
        self.defensePoints = defensePoints
        self.hitPoints = hitPoints
        self.manaPoints = manaPoints
        self.strength = strength
        self.agility = agility
        self.power = power
        self.instinct = instinct
        self.endurance = endurance
        self.partsProtection = partsProtection
        self.drops = drops
    }

    // MARK: - Derived

    /// Number of strikes per round = number of attack profiles present.
    public var attackPoints: Int { leftAttack != nil ? 2 : 1 }
}

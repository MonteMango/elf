//
//  CombatantSnapshot.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

// MARK: - CombatantType

public enum CombatantType: Sendable, Hashable {
    case elf
    case monster
}

// MARK: - CombatantSnapshot

/// A unified snapshot of a combatant's state for battle calculations.
/// This struct captures all relevant combat stats from either an ElfHero or Monster,
/// enabling unified battle logic regardless of combatant type.
public struct CombatantSnapshot: Sendable, Identifiable, Hashable {

    // MARK: - Identity

    /// Unique identifier for this snapshot instance
    public let id: UUID

    /// Original ID from the source entity (ElfInfo.id or Monster.id)
    public let sourceId: UUID

    /// Display name of the combatant
    public let name: String

    /// Image asset name for UI display
    public let imageName: String

    /// Type of combatant (elf or monster)
    public let combatantType: CombatantType

    /// Level of the combatant
    public let level: Int16

    // MARK: - Health

    /// Current hit points (mutable during battle)
    public var currentHP: Int

    /// Maximum hit points
    public let maxHP: Int

    // MARK: - Attributes

    /// Strength attribute - affects damage dealt
    public let strength: Int

    /// Agility attribute - affects dodge chance, reduces enemy crit multiplier
    public let agility: Int

    /// Power attribute - affects critical hit chance
    public let power: Int

    /// Intuition attribute - reduces enemy dodge/crit chance
    public let intuition: Int

    // MARK: - Combat Points

    /// Number of attack points per round
    public let attackPoints: Int

    /// Number of defense points per round
    public let defensePoints: Int

    // MARK: - Damage

    /// Minimum attack damage (from weapon or natural attack)
    public let minimumAttack: Int

    /// Maximum attack damage (from weapon or natural attack)
    public let maximumAttack: Int

    // MARK: - Armor

    /// Armor values per body part
    public let armorValues: [BodyPart: Int]

    // MARK: - Equipment (nullable - monsters may or may not have equipment)

    /// Head armor item
    public let helmetItem: ElfDefenseItem?

    /// Hand armor item
    public let glovesItem: ElfDefenseItem?

    /// Feet armor item
    public let shoesItem: ElfDefenseItem?

    /// Upper body armor item
    public let upperBodyItem: ElfDefenseItem?

    /// Lower body armor item
    public let bottomBodyItem: ElfDefenseItem?

    /// Robe item (worn over armor)
    public let robeItem: ElfRobeItem?

    /// Weapon in left hand
    public let leftWeaponItem: ElfWeaponItem?

    /// Weapon in right hand
    public let rightWeaponItem: ElfWeaponItem?

    /// Shield item
    public let shieldItem: ElfShieldItem?

    /// Ring accessory
    public let ringItem: ElfJewelryItem?

    /// Necklace accessory
    public let necklaceItem: ElfJewelryItem?

    /// Earrings accessory
    public let earringsItem: ElfJewelryItem?

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        sourceId: UUID,
        name: String,
        imageName: String,
        combatantType: CombatantType,
        level: Int16 = 1,
        currentHP: Int,
        maxHP: Int,
        strength: Int,
        agility: Int,
        power: Int,
        intuition: Int,
        attackPoints: Int,
        defensePoints: Int,
        minimumAttack: Int,
        maximumAttack: Int,
        armorValues: [BodyPart: Int],
        helmetItem: ElfDefenseItem? = nil,
        glovesItem: ElfDefenseItem? = nil,
        shoesItem: ElfDefenseItem? = nil,
        upperBodyItem: ElfDefenseItem? = nil,
        bottomBodyItem: ElfDefenseItem? = nil,
        robeItem: ElfRobeItem? = nil,
        leftWeaponItem: ElfWeaponItem? = nil,
        rightWeaponItem: ElfWeaponItem? = nil,
        shieldItem: ElfShieldItem? = nil,
        ringItem: ElfJewelryItem? = nil,
        necklaceItem: ElfJewelryItem? = nil,
        earringsItem: ElfJewelryItem? = nil
    ) {
        self.id = id
        self.sourceId = sourceId
        self.name = name
        self.imageName = imageName
        self.combatantType = combatantType
        self.level = level
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.strength = strength
        self.agility = agility
        self.power = power
        self.intuition = intuition
        self.attackPoints = attackPoints
        self.defensePoints = defensePoints
        self.minimumAttack = minimumAttack
        self.maximumAttack = maximumAttack
        self.armorValues = armorValues
        self.helmetItem = helmetItem
        self.glovesItem = glovesItem
        self.shoesItem = shoesItem
        self.upperBodyItem = upperBodyItem
        self.bottomBodyItem = bottomBodyItem
        self.robeItem = robeItem
        self.leftWeaponItem = leftWeaponItem
        self.rightWeaponItem = rightWeaponItem
        self.shieldItem = shieldItem
        self.ringItem = ringItem
        self.necklaceItem = necklaceItem
        self.earringsItem = earringsItem
    }

    // MARK: - Computed Properties

    /// Whether the combatant is still alive
    public var isAlive: Bool {
        currentHP > 0
    }

    /// HP as a percentage (0.0 to 1.0)
    public var hpPercentage: Double {
        guard maxHP > 0 else { return 0 }
        return Double(currentHP) / Double(maxHP)
    }

    /// Whether the combatant has any equipment
    public var hasEquipment: Bool {
        helmetItem != nil ||
        glovesItem != nil ||
        shoesItem != nil ||
        upperBodyItem != nil ||
        bottomBodyItem != nil ||
        robeItem != nil ||
        leftWeaponItem != nil ||
        rightWeaponItem != nil ||
        shieldItem != nil ||
        ringItem != nil ||
        necklaceItem != nil ||
        earringsItem != nil
    }
}

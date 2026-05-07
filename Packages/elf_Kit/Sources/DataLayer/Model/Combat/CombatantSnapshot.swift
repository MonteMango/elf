//
//  CombatantSnapshot.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

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

    /// Level of the combatant (1-12)
    public let level: Int

    // MARK: - Health

    /// Current hit points (mutable during battle)
    public var currentHP: Int

    /// Maximum hit points
    public let maxHP: Int

    // MARK: - Endurance Points

    /// Current endurance points (mutable during battle, spent on blocks)
    public var currentEP: Int

    /// Maximum endurance points
    public let maxEP: Int

    // MARK: - Attributes

    /// Strength attribute - affects damage dealt
    public let strength: Int

    /// Agility attribute - affects dodge chance, reduces enemy crit multiplier
    public let agility: Int

    /// Power attribute - affects critical hit chance
    public let power: Int

    /// Intuition attribute - reduces enemy dodge/crit chance
    public let intuition: Int

    /// Endurance attribute - reserved for the EP/block-cost system (not yet read by combat math)
    public let endurance: Int

    // MARK: - Attacks

    /// Per-strike profile (damage range + EP-block cost). One element per
    /// attack point per round.
    ///
    /// Hero: index 0 is the primary (right-hand) weapon; index 1 (when
    /// dual-wielding) is the off-hand weapon. Monster: index 0 is
    /// `Monster.rightAttack`, index 1 is `Monster.leftAttack` when present.
    ///
    /// `ElfSnapshotCombatCalculator` walks body parts in a fixed order and
    /// the i-th attacked body part consumes `attacks[i]`.
    public let attacks: [AttackProfile]

    // MARK: - Combat Points

    /// Number of attack points per round (= `attacks.count`).
    public var attackPoints: Int { attacks.count }

    /// Number of defense points per round
    public let defensePoints: Int

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
        level: Int = 1,
        currentHP: Int,
        maxHP: Int,
        currentEP: Int,
        maxEP: Int,
        strength: Int,
        agility: Int,
        power: Int,
        intuition: Int,
        endurance: Int,
        attacks: [AttackProfile],
        defensePoints: Int,
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
        self.currentEP = currentEP
        self.maxEP = maxEP
        self.strength = strength
        self.agility = agility
        self.power = power
        self.intuition = intuition
        self.endurance = endurance
        self.attacks = attacks
        self.defensePoints = defensePoints
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

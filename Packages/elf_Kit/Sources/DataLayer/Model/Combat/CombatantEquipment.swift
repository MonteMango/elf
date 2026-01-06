//
//  CombatantEquipment.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Grouped equipment for a combatant.
///
/// This struct organizes equipment into logical groups (armor, weapons, jewelry)
/// instead of having 12 separate optional fields.
///
/// ## Usage
/// ```swift
/// let equipment = CombatantEquipment(
///     armor: CombatantArmor(helmet: helmetItem, ...),
///     weapons: CombatantWeapons.dualWield(left: sword, right: dagger),
///     jewelry: CombatantJewelry(ring: ring, ...)
/// )
///
/// if equipment.isEmpty { print("No equipment") }
/// ```
public struct CombatantEquipment: Sendable, Hashable, Equatable {

    /// Armor pieces
    public let armor: CombatantArmor

    /// Weapons and shield configuration
    public let weapons: CombatantWeapons

    /// Jewelry accessories
    public let jewelry: CombatantJewelry

    /// Whether the combatant has no equipment at all
    public var isEmpty: Bool {
        armor.isEmpty && weapons.isEmpty && jewelry.isEmpty
    }

    /// No equipment at all
    public static let none = CombatantEquipment(
        armor: .none,
        weapons: .none,
        jewelry: .none
    )

    public init(
        armor: CombatantArmor = .none,
        weapons: CombatantWeapons = .none,
        jewelry: CombatantJewelry = .none
    ) {
        self.armor = armor
        self.weapons = weapons
        self.jewelry = jewelry
    }

    /// Creates equipment from individual optional items (for backward compatibility)
    public init(
        helmet: ElfDefenseItem? = nil,
        gloves: ElfDefenseItem? = nil,
        shoes: ElfDefenseItem? = nil,
        upperBody: ElfDefenseItem? = nil,
        bottomBody: ElfDefenseItem? = nil,
        robe: ElfRobeItem? = nil,
        leftWeapon: ElfWeaponItem? = nil,
        rightWeapon: ElfWeaponItem? = nil,
        shield: ElfShieldItem? = nil,
        ring: ElfJewelryItem? = nil,
        necklace: ElfJewelryItem? = nil,
        earrings: ElfJewelryItem? = nil
    ) {
        self.armor = CombatantArmor(
            helmet: helmet,
            gloves: gloves,
            shoes: shoes,
            upperBody: upperBody,
            bottomBody: bottomBody,
            robe: robe
        )
        self.weapons = CombatantWeapons(
            leftWeapon: leftWeapon,
            rightWeapon: rightWeapon,
            shield: shield
        )
        self.jewelry = CombatantJewelry(
            ring: ring,
            necklace: necklace,
            earrings: earrings
        )
    }
}

// MARK: - Armor Group

/// Armor equipment group (defensive gear worn on body)
public struct CombatantArmor: Sendable, Hashable, Equatable {

    /// Head armor
    public let helmet: ElfDefenseItem?

    /// Hand armor
    public let gloves: ElfDefenseItem?

    /// Feet armor
    public let shoes: ElfDefenseItem?

    /// Upper body armor (chest)
    public let upperBody: ElfDefenseItem?

    /// Lower body armor (legs)
    public let bottomBody: ElfDefenseItem?

    /// Robe (worn over armor)
    public let robe: ElfRobeItem?

    /// Whether no armor is equipped
    public var isEmpty: Bool {
        helmet == nil &&
        gloves == nil &&
        shoes == nil &&
        upperBody == nil &&
        bottomBody == nil &&
        robe == nil
    }

    /// Count of equipped armor pieces
    public var equippedCount: Int {
        [helmet, gloves, shoes, upperBody, bottomBody].compactMap { $0 }.count +
        (robe != nil ? 1 : 0)
    }

    /// No armor equipped
    public static let none = CombatantArmor()

    public init(
        helmet: ElfDefenseItem? = nil,
        gloves: ElfDefenseItem? = nil,
        shoes: ElfDefenseItem? = nil,
        upperBody: ElfDefenseItem? = nil,
        bottomBody: ElfDefenseItem? = nil,
        robe: ElfRobeItem? = nil
    ) {
        self.helmet = helmet
        self.gloves = gloves
        self.shoes = shoes
        self.upperBody = upperBody
        self.bottomBody = bottomBody
        self.robe = robe
    }

    /// All equipped defense items (excluding robe)
    public var allDefenseItems: [ElfDefenseItem] {
        [helmet, gloves, shoes, upperBody, bottomBody].compactMap { $0 }
    }
}

// MARK: - Weapons Group

/// Weapons equipment group (offensive and defensive hand items)
public struct CombatantWeapons: Sendable, Hashable, Equatable {

    /// Weapon in left hand
    public let leftWeapon: ElfWeaponItem?

    /// Weapon in right hand
    public let rightWeapon: ElfWeaponItem?

    /// Shield (if equipped)
    public let shield: ElfShieldItem?

    /// Whether no weapons or shield are equipped
    public var isEmpty: Bool {
        leftWeapon == nil && rightWeapon == nil && shield == nil
    }

    /// No weapons equipped
    public static let none = CombatantWeapons()

    public init(
        leftWeapon: ElfWeaponItem? = nil,
        rightWeapon: ElfWeaponItem? = nil,
        shield: ElfShieldItem? = nil
    ) {
        self.leftWeapon = leftWeapon
        self.rightWeapon = rightWeapon
        self.shield = shield
    }

    /// Primary weapon (prefers right hand)
    public var primaryWeapon: ElfWeaponItem? {
        rightWeapon ?? leftWeapon
    }

    /// Whether dual wielding
    public var isDualWield: Bool {
        leftWeapon != nil && rightWeapon != nil
    }

    /// Whether using shield
    public var hasShield: Bool {
        shield != nil
    }

    /// All equipped weapons
    public var allWeapons: [ElfWeaponItem] {
        [leftWeapon, rightWeapon].compactMap { $0 }
    }
}

// MARK: - Jewelry Group

/// Jewelry equipment group (accessory items)
public struct CombatantJewelry: Sendable, Hashable, Equatable {

    /// Ring accessory
    public let ring: ElfJewelryItem?

    /// Necklace accessory
    public let necklace: ElfJewelryItem?

    /// Earrings accessory
    public let earrings: ElfJewelryItem?

    /// Whether no jewelry is equipped
    public var isEmpty: Bool {
        ring == nil && necklace == nil && earrings == nil
    }

    /// Count of equipped jewelry
    public var equippedCount: Int {
        [ring, necklace, earrings].compactMap { $0 }.count
    }

    /// No jewelry equipped
    public static let none = CombatantJewelry()

    public init(
        ring: ElfJewelryItem? = nil,
        necklace: ElfJewelryItem? = nil,
        earrings: ElfJewelryItem? = nil
    ) {
        self.ring = ring
        self.necklace = necklace
        self.earrings = earrings
    }

    /// All equipped jewelry
    public var allJewelry: [ElfJewelryItem] {
        [ring, necklace, earrings].compactMap { $0 }
    }
}

// MARK: - Extension for CombatantSnapshot

extension CombatantSnapshot {
    /// Creates a CombatantEquipment from this snapshot's equipment fields.
    /// Useful for working with grouped equipment in new code.
    public var equipment: CombatantEquipment {
        CombatantEquipment(
            helmet: helmetItem,
            gloves: glovesItem,
            shoes: shoesItem,
            upperBody: upperBodyItem,
            bottomBody: bottomBodyItem,
            robe: robeItem,
            leftWeapon: leftWeaponItem,
            rightWeapon: rightWeaponItem,
            shield: shieldItem,
            ring: ringItem,
            necklace: necklaceItem,
            earrings: earringsItem
        )
    }
}

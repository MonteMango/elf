//
//  EquippedItems.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Container for all equipped items on an elf.
/// Uses WeaponConfiguration enum to ensure valid weapon/shield combinations.
public struct EquippedItems: Sendable, Equatable {

    // MARK: - Weapons (type-safe configuration)

    public var weapons: WeaponConfiguration

    // MARK: - Armor

    public var helmet: ElfDefenseItem?
    public var gloves: ElfDefenseItem?
    public var shoes: ElfDefenseItem?
    public var upperBody: ElfDefenseItem?
    public var bottomBody: ElfDefenseItem?

    // MARK: - Clothing

    public var shirt: ElfRobeItem?

    // MARK: - Jewelry

    public var ring: ElfJewelryItem?
    public var necklace: ElfJewelryItem?
    public var earrings: ElfJewelryItem?

    // MARK: - Initialization

    public init(
        weapons: WeaponConfiguration,
        helmet: ElfDefenseItem? = nil,
        gloves: ElfDefenseItem? = nil,
        shoes: ElfDefenseItem? = nil,
        upperBody: ElfDefenseItem? = nil,
        bottomBody: ElfDefenseItem? = nil,
        shirt: ElfRobeItem? = nil,
        ring: ElfJewelryItem? = nil,
        necklace: ElfJewelryItem? = nil,
        earrings: ElfJewelryItem? = nil
    ) {
        self.weapons = weapons
        self.helmet = helmet
        self.gloves = gloves
        self.shoes = shoes
        self.upperBody = upperBody
        self.bottomBody = bottomBody
        self.shirt = shirt
        self.ring = ring
        self.necklace = necklace
        self.earrings = earrings
    }

    // MARK: - Convenience Accessors

    /// Returns the primary weapon (always present)
    public var weapon: ElfWeaponItem {
        weapons.weapon
    }

    /// Returns the shield if equipped
    public var shield: ElfShieldItem? {
        weapons.shield
    }

    /// Returns the secondary weapon for dual-wield configuration
    public var secondaryWeapon: ElfWeaponItem? {
        weapons.secondaryWeapon
    }

    // MARK: - Helper Methods

    /// Checks if the given item ID is equipped anywhere
    public func isEquipped(_ itemId: UUID) -> Bool {
        allEquippedIds.contains(itemId)
    }

    /// Returns all equipped item IDs
    public var allEquippedIds: Set<UUID> {
        var ids = weapons.allItemIds
        if let helmet { ids.insert(helmet.id) }
        if let gloves { ids.insert(gloves.id) }
        if let shoes { ids.insert(shoes.id) }
        if let upperBody { ids.insert(upperBody.id) }
        if let bottomBody { ids.insert(bottomBody.id) }
        if let shirt { ids.insert(shirt.id) }
        if let ring { ids.insert(ring.id) }
        if let necklace { ids.insert(necklace.id) }
        if let earrings { ids.insert(earrings.id) }
        return ids
    }

    /// Get equipped item ID for a slot (for UI compatibility)
    /// Returns the instance ID (unique per item instance)
    public func equippedItemId(for slot: HeroItemType) -> UUID? {
        switch slot {
        case .weapons: return weapons.weapon.id
        case .shields: return weapons.shield?.id
        case .helmet: return helmet?.id
        case .gloves: return gloves?.id
        case .shoes: return shoes?.id
        case .upperBody: return upperBody?.id
        case .bottomBody: return bottomBody?.id
        case .shirt: return shirt?.id
        case .ring: return ring?.id
        case .necklace: return necklace?.id
        case .earrings: return earrings?.id
        }
    }

    /// Get equipped base item ID for a slot (for image lookup and repository queries)
    /// Returns the base item ID from JSON
    public func equippedBaseItemId(for slot: HeroItemType) -> UUID? {
        switch slot {
        case .weapons: return weapons.weapon.item.id
        case .shields: return weapons.shield?.item.id
        case .helmet: return helmet?.item.id
        case .gloves: return gloves?.item.id
        case .shoes: return shoes?.item.id
        case .upperBody: return upperBody?.item.id
        case .bottomBody: return bottomBody?.item.id
        case .shirt: return shirt?.item.id
        case .ring: return ring?.item.id
        case .necklace: return necklace?.item.id
        case .earrings: return earrings?.item.id
        }
    }

    /// Get all equipped base item IDs as dictionary (for UI compatibility)
    public var equippedBaseItemIds: [HeroItemType: UUID] {
        var result: [HeroItemType: UUID] = [:]
        result[.weapons] = weapons.weapon.item.id
        if let shield = weapons.shield { result[.shields] = shield.item.id }
        if let helmet { result[.helmet] = helmet.item.id }
        if let gloves { result[.gloves] = gloves.item.id }
        if let shoes { result[.shoes] = shoes.item.id }
        if let upperBody { result[.upperBody] = upperBody.item.id }
        if let bottomBody { result[.bottomBody] = bottomBody.item.id }
        if let shirt { result[.shirt] = shirt.item.id }
        if let ring { result[.ring] = ring.item.id }
        if let necklace { result[.necklace] = necklace.item.id }
        if let earrings { result[.earrings] = earrings.item.id }
        return result
    }

    // MARK: - Equatable

    public static func == (lhs: EquippedItems, rhs: EquippedItems) -> Bool {
        lhs.weapons == rhs.weapons
            && lhs.helmet?.id == rhs.helmet?.id
            && lhs.gloves?.id == rhs.gloves?.id
            && lhs.shoes?.id == rhs.shoes?.id
            && lhs.upperBody?.id == rhs.upperBody?.id
            && lhs.bottomBody?.id == rhs.bottomBody?.id
            && lhs.shirt?.id == rhs.shirt?.id
            && lhs.ring?.id == rhs.ring?.id
            && lhs.necklace?.id == rhs.necklace?.id
            && lhs.earrings?.id == rhs.earrings?.id
    }
}

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

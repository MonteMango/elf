//
//  ElfInventory.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.12.25.
//

import Foundation

/// Container for all items owned by an elf.
/// Unlimited capacity for all item types.
/// Note: Not Codable directly - use InventorySaveData for persistence.
public struct ElfInventory: Sendable, Equatable {

    // MARK: - Equipment Collections

    /// Weapons in inventory
    public var weapons: [ElfWeaponItem]

    /// Shields in inventory
    public var shields: [ElfShieldItem]

    /// Defense items (helmets, gloves, shoes, upper/bottom body)
    public var armor: [ElfDefenseItem]

    /// Robes in inventory
    public var robes: [ElfRobeItem]

    /// Jewelry items (rings, necklaces, earrings)
    public var jewelry: [ElfJewelryItem]

    // MARK: - Materials Collection

    /// Stackable materials
    public var materials: [InventoryMaterial]

    // MARK: - Initialization

    /// Creates an empty inventory
    public init() {
        self.weapons = []
        self.shields = []
        self.armor = []
        self.robes = []
        self.jewelry = []
        self.materials = []
    }

}

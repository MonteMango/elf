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

    /// Creates inventory with specified items
    public init(
        weapons: [ElfWeaponItem] = [],
        shields: [ElfShieldItem] = [],
        armor: [ElfDefenseItem] = [],
        robes: [ElfRobeItem] = [],
        jewelry: [ElfJewelryItem] = [],
        materials: [InventoryMaterial] = []
    ) {
        self.weapons = weapons
        self.shields = shields
        self.armor = armor
        self.robes = robes
        self.jewelry = jewelry
        self.materials = materials
    }

    // MARK: - Add Equipment Methods

    /// Adds a weapon to inventory
    public mutating func addWeapon(_ weapon: ElfWeaponItem) {
        weapons.append(weapon)
    }

    /// Adds a shield to inventory
    public mutating func addShield(_ shield: ElfShieldItem) {
        shields.append(shield)
    }

    /// Adds an armor piece to inventory
    public mutating func addArmor(_ defense: ElfDefenseItem) {
        armor.append(defense)
    }

    /// Adds a robe to inventory
    public mutating func addRobe(_ robe: ElfRobeItem) {
        robes.append(robe)
    }

    /// Adds jewelry to inventory
    public mutating func addJewelry(_ item: ElfJewelryItem) {
        jewelry.append(item)
    }

    // MARK: - Add Material Methods

    /// Adds material to inventory. Stacks with existing material of same ID.
    public mutating func addMaterial(id: UUID, quantity: Int = 1) {
        guard quantity > 0 else { return }

        // Find existing material and stack
        if let index = materials.firstIndex(where: { $0.id == id }) {
            materials[index].quantity += quantity
        } else {
            // Create new material entry
            materials.append(InventoryMaterial(id: id, quantity: quantity))
        }
    }

    /// Adds material from InventoryMaterial struct
    public mutating func addMaterial(_ material: InventoryMaterial) {
        addMaterial(id: material.id, quantity: material.quantity)
    }

    // MARK: - Remove Methods

    /// Removes a weapon by instance ID
    public mutating func removeWeapon(id: UUID) {
        weapons.removeAll { $0.id == id }
    }

    /// Removes a shield by instance ID
    public mutating func removeShield(id: UUID) {
        shields.removeAll { $0.id == id }
    }

    /// Removes armor by instance ID
    public mutating func removeArmor(id: UUID) {
        armor.removeAll { $0.id == id }
    }

    /// Removes a robe by instance ID
    public mutating func removeRobe(id: UUID) {
        robes.removeAll { $0.id == id }
    }

    /// Removes jewelry by instance ID
    public mutating func removeJewelry(id: UUID) {
        jewelry.removeAll { $0.id == id }
    }

    /// Removes material by ID and quantity. Returns actual amount removed.
    @discardableResult
    public mutating func removeMaterial(id: UUID, quantity: Int = 1) -> Int {
        guard let index = materials.firstIndex(where: { $0.id == id }) else {
            return 0
        }

        let available = materials[index].quantity
        let toRemove = min(available, quantity)

        if toRemove >= available {
            materials.remove(at: index)
        } else {
            materials[index].quantity -= toRemove
        }

        return toRemove
    }

    // MARK: - Query Methods

    /// Returns quantity of a specific material
    public func materialQuantity(id: UUID) -> Int {
        materials.first { $0.id == id }?.quantity ?? 0
    }

    /// Checks if inventory has at least specified quantity of material
    public func hasMaterial(id: UUID, quantity: Int = 1) -> Bool {
        materialQuantity(id: id) >= quantity
    }

    /// Total count of all equipment items
    public var totalEquipmentCount: Int {
        weapons.count + shields.count + armor.count + robes.count + jewelry.count
    }

    /// Total count of all material stacks
    public var totalMaterialStacks: Int {
        materials.count
    }

    /// Total quantity of all materials
    public var totalMaterialQuantity: Int {
        materials.reduce(0) { $0 + $1.quantity }
    }
}

//
//  InventorySaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.12.25.
//

import Foundation

/// DTO container for inventory persistence.
/// Aggregates all inventory item DTOs for save/load operations.
public struct InventorySaveData: Sendable, Equatable, Codable {
    public let weapons: [WeaponSaveData]
    public let shields: [ShieldSaveData]
    public let armor: [DefenseSaveData]
    public let robes: [RobeSaveData]
    public let jewelry: [JewelrySaveData]
    public let materials: [MaterialSaveData]

    public init(
        weapons: [WeaponSaveData] = [],
        shields: [ShieldSaveData] = [],
        armor: [DefenseSaveData] = [],
        robes: [RobeSaveData] = [],
        jewelry: [JewelrySaveData] = [],
        materials: [MaterialSaveData] = []
    ) {
        self.weapons = weapons
        self.shields = shields
        self.armor = armor
        self.robes = robes
        self.jewelry = jewelry
        self.materials = materials
    }

    /// Create from ElfInventory
    public init(from inventory: ElfInventory) {
        self.weapons = inventory.weapons.map { WeaponSaveData(from: $0) }
        self.shields = inventory.shields.map { ShieldSaveData(from: $0) }
        self.armor = inventory.armor.map { DefenseSaveData(from: $0) }
        self.robes = inventory.robes.map { RobeSaveData(from: $0) }
        self.jewelry = inventory.jewelry.map { JewelrySaveData(from: $0) }
        self.materials = inventory.materials.map { MaterialSaveData(from: $0) }
    }

    /// Convert back to ElfInventory using ItemsRepository
    /// - Throws: `GameSaveError.missingItemData` if any item cannot be restored
    public func toElfInventory(itemsRepository: ItemsRepository) throws -> ElfInventory {
        var inventory = ElfInventory()

        // Restore weapons
        for weaponData in weapons {
            guard let weapon = weaponData.toElfWeaponItem(using: itemsRepository) else {
                throw GameSaveError.missingItemData(itemId: weaponData.itemId, itemType: "weapon")
            }
            inventory.addWeapon(weapon)
        }

        // Restore shields
        for shieldData in shields {
            guard let shield = shieldData.toElfShieldItem(using: itemsRepository) else {
                throw GameSaveError.missingItemData(itemId: shieldData.itemId, itemType: "shield")
            }
            inventory.addShield(shield)
        }

        // Restore armor
        for armorData in armor {
            guard let defense = armorData.toElfDefenseItem(using: itemsRepository) else {
                throw GameSaveError.missingItemData(itemId: armorData.itemId, itemType: "armor")
            }
            inventory.addArmor(defense)
        }

        // Restore robes
        for robeData in robes {
            guard let robe = robeData.toElfRobeItem(using: itemsRepository) else {
                throw GameSaveError.missingItemData(itemId: robeData.itemId, itemType: "robe")
            }
            inventory.addRobe(robe)
        }

        // Restore jewelry
        for jewelryData in jewelry {
            guard let jewelryItem = jewelryData.toElfJewelryItem(using: itemsRepository) else {
                throw GameSaveError.missingItemData(itemId: jewelryData.itemId, itemType: "jewelry")
            }
            inventory.addJewelry(jewelryItem)
        }

        // Restore materials (simple copy)
        for materialData in materials {
            inventory.addMaterial(id: materialData.id, quantity: materialData.quantity)
        }

        return inventory
    }
}

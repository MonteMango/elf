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

    /// Create from ElfInventory
    public init(from inventory: ElfInventory) {
        self.weapons = inventory.weapons.map { WeaponSaveData(from: $0) }
        self.shields = inventory.shields.map { ShieldSaveData(from: $0) }
        self.armor = inventory.armor.map { DefenseSaveData(from: $0) }
        self.robes = inventory.robes.map { RobeSaveData(from: $0) }
        self.jewelry = inventory.jewelry.map { JewelrySaveData(from: $0) }
        self.materials = inventory.materials.map { MaterialSaveData(from: $0) }
    }

    /// Convert back to ElfInventory using ItemsRepository and InventoryService
    /// - Throws: `GameSaveError.missingItemData` if any item cannot be restored
    public func toElfInventory(
        itemsRepository: ItemsRepository,
        inventoryService: InventoryService
    ) throws -> ElfInventory {
        var inventory = ElfInventory()

        // Restore weapons
        for weaponData in weapons {
            guard let weapon = weaponData.toElfWeaponItem(using: itemsRepository) else {
                throw GameSaveError.missingItemData(itemId: weaponData.itemId, itemType: "weapon")
            }
            inventory = inventoryService.addWeapon(weapon, to: inventory)
        }

        // Restore shields
        for shieldData in shields {
            guard let shield = shieldData.toElfShieldItem(using: itemsRepository) else {
                throw GameSaveError.missingItemData(itemId: shieldData.itemId, itemType: "shield")
            }
            inventory = inventoryService.addShield(shield, to: inventory)
        }

        // Restore armor
        for armorData in armor {
            guard let defense = armorData.toElfDefenseItem(using: itemsRepository) else {
                throw GameSaveError.missingItemData(itemId: armorData.itemId, itemType: "armor")
            }
            inventory = inventoryService.addArmor(defense, to: inventory)
        }

        // Restore robes
        for robeData in robes {
            guard let robe = robeData.toElfRobeItem(using: itemsRepository) else {
                throw GameSaveError.missingItemData(itemId: robeData.itemId, itemType: "robe")
            }
            inventory = inventoryService.addRobe(robe, to: inventory)
        }

        // Restore jewelry
        for jewelryData in jewelry {
            guard let jewelryItem = jewelryData.toElfJewelryItem(using: itemsRepository) else {
                throw GameSaveError.missingItemData(itemId: jewelryData.itemId, itemType: "jewelry")
            }
            inventory = inventoryService.addJewelry(jewelryItem, to: inventory)
        }

        // Restore materials in a single pass
        let materialAdditions = materials.map {
            MaterialAddition(id: $0.id, source: $0.source, quantity: $0.quantity)
        }
        inventory = inventoryService.addMaterials(materialAdditions, to: inventory)

        return inventory
    }
}

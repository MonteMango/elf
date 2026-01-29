//
//  ElfInventoryService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Default implementation of inventory service
///
/// All operations follow immutable pattern - they create and return new inventory instances
/// rather than mutating the original.
public final class ElfInventoryService: InventoryService {

    // MARK: - Initialization

    public init() {}

    // MARK: - Add Equipment

    public func addWeapon(_ weapon: ElfWeaponItem, to inventory: ElfInventory) -> ElfInventory {
        var newInventory = inventory
        newInventory.weapons.append(weapon)
        return newInventory
    }

    public func addShield(_ shield: ElfShieldItem, to inventory: ElfInventory) -> ElfInventory {
        var newInventory = inventory
        newInventory.shields.append(shield)
        return newInventory
    }

    public func addArmor(_ armor: ElfDefenseItem, to inventory: ElfInventory) -> ElfInventory {
        var newInventory = inventory
        newInventory.armor.append(armor)
        return newInventory
    }

    public func addRobe(_ robe: ElfRobeItem, to inventory: ElfInventory) -> ElfInventory {
        var newInventory = inventory
        newInventory.robes.append(robe)
        return newInventory
    }

    public func addJewelry(_ jewelry: ElfJewelryItem, to inventory: ElfInventory) -> ElfInventory {
        var newInventory = inventory
        newInventory.jewelry.append(jewelry)
        return newInventory
    }

    // MARK: - Add Materials

    public func addMaterial(id: UUID, quantity: Int, to inventory: ElfInventory) -> ElfInventory {
        guard quantity > 0 else { return inventory }

        var newInventory = inventory

        if let index = newInventory.materials.firstIndex(where: { $0.id == id }) {
            newInventory.materials[index].quantity += quantity
        } else {
            newInventory.materials.append(InventoryMaterial(id: id, quantity: quantity))
        }

        return newInventory
    }
}



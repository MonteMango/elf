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

    // MARK: - Add Crafted Item

    public func addCraftedItem(_ item: Item, to inventory: ElfInventory) -> ElfInventory {
        switch item {
        case let weapon as WeaponItem:
            let elfWeapon = ElfWeaponItem(id: UUID(), item: weapon, enchantLevel: 0)
            return addWeapon(elfWeapon, to: inventory)
        case let defense as DefenseItem:
            let elfArmor = ElfDefenseItem(id: UUID(), item: defense)
            return addArmor(elfArmor, to: inventory)
        case let shield as ShieldItem:
            let elfShield = ElfShieldItem(id: UUID(), item: shield)
            return addShield(elfShield, to: inventory)
        case let robe as RobeItem:
            let elfRobe = ElfRobeItem(id: UUID(), item: robe)
            return addRobe(elfRobe, to: inventory)
        default:
            return inventory
        }
    }

    // MARK: - Add Materials

    public func addMaterial(id: UUID, source: MaterialSource, quantity: Int, to inventory: ElfInventory) -> ElfInventory {
        guard quantity > 0 else { return inventory }

        var newInventory = inventory

        if let index = newInventory.materials.firstIndex(where: { $0.id == id }) {
            newInventory.materials[index].quantity += quantity
        } else {
            newInventory.materials.append(InventoryMaterial(id: id, source: source, quantity: quantity))
        }

        return newInventory
    }

    public func addMaterials(_ materials: [MaterialAddition], to inventory: ElfInventory) -> ElfInventory {
        guard !materials.isEmpty else { return inventory }

        // Single local accumulator: after the first append/update the `materials`
        // buffer is uniquely owned, so subsequent iterations mutate in-place.
        var newInventory = inventory
        for addition in materials where addition.quantity > 0 {
            if let index = newInventory.materials.firstIndex(where: { $0.id == addition.id }) {
                newInventory.materials[index].quantity += addition.quantity
            } else {
                newInventory.materials.append(
                    InventoryMaterial(id: addition.id, source: addition.source, quantity: addition.quantity)
                )
            }
        }
        return newInventory
    }
}

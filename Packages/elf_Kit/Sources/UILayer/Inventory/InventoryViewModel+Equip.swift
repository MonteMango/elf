//
//  InventoryViewModel+Equip.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Equip/Unequip Logic

extension InventoryViewModel {

    func equipItem(_ item: InventoryDisplayItem) async {
        switch item.itemDetails {
        case .weapon:  await equipmentService.equipWeapon(id: item.id)
        case .shield:  await equipmentService.equipShield(id: item.id)
        case .armor:   await equipmentService.equipArmor(id: item.id)
        case .jewelry: await equipmentService.equipJewelry(id: item.id)
        default:       break
        }
    }

    func unequipItem(_ item: InventoryDisplayItem) async {
        switch item.itemDetails {
        case .weapon:  await equipmentService.unequipWeapon(id: item.id)
        case .shield:  await equipmentService.unequipShield()
        case .armor:   await equipmentService.unequipArmor(id: item.id)
        case .jewelry: await equipmentService.unequipJewelry(id: item.id)
        default:       break
        }
    }

}

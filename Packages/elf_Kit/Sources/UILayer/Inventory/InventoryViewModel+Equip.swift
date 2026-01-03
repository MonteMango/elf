//
//  InventoryViewModel+Equip.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Equip/Unequip Logic

extension InventoryViewModel {

    func equipItem(_ item: InventoryDisplayItem) {
        switch item.itemDetails {
        case .weapon:  equipmentService.equipWeapon(id: item.id)
        case .shield:  equipmentService.equipShield(id: item.id)
        case .armor:   equipmentService.equipArmor(id: item.id)
        case .jewelry: equipmentService.equipJewelry(id: item.id)
        default:       break
        }
    }

    func unequipItem(_ item: InventoryDisplayItem) {
        switch item.itemDetails {
        case .weapon:  equipmentService.unequipWeapon(id: item.id)
        case .shield:  equipmentService.unequipShield()
        case .armor:   equipmentService.unequipArmor(id: item.id)
        case .jewelry: equipmentService.unequipJewelry(id: item.id)
        default:       break
        }
    }

    func canUnequipItem(_ item: InventoryDisplayItem) -> Bool {
        switch item.itemDetails {
        case .weapon: return equipmentService.canUnequipWeapon()
        default:      return true
        }
    }
}

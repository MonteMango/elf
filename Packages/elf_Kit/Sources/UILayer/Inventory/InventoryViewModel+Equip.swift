//
//  InventoryViewModel+Equip.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Equip/Unequip Logic

extension InventoryViewModel {

    func equipItem(_ item: InventoryItemDisplay) {
        switch item.itemDetails {
        case .weapon:
            // Shields sub-tab carries off-hand intent: any one-handed weapon tapped here
            // goes into the off-hand slot, forming a dual-wield. Other tabs go to main hand.
            if selectedWeaponSubcategory == .shields {
                equipmentService.equipOffhandWeapon(id: item.id)
            } else {
                equipmentService.equipWeapon(id: item.id)
            }
        case .shield:  equipmentService.equipShield(id: item.id)
        case .armor:   equipmentService.equipArmor(id: item.id)
        case .jewelry: equipmentService.equipJewelry(id: item.id)
        default:       break
        }
    }

    func unequipItem(_ item: InventoryItemDisplay) {
        switch item.itemDetails {
        case .weapon:  equipmentService.unequipWeapon(id: item.id)
        case .shield:  equipmentService.unequipShield()
        case .armor:   equipmentService.unequipArmor(id: item.id)
        case .jewelry: equipmentService.unequipJewelry(id: item.id)
        default:       break
        }
    }

}

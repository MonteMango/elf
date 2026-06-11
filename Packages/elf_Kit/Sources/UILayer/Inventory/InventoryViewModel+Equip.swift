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
                session.equipOffhandWeapon(id: OwnedItemID(rawValue: item.id))
            } else {
                session.equipWeapon(id: OwnedItemID(rawValue: item.id))
            }
        case .shield:  session.equipShield(id: OwnedItemID(rawValue: item.id))
        case .armor:   session.equipArmor(id: OwnedItemID(rawValue: item.id))
        case .jewelry: session.equipJewelry(id: OwnedItemID(rawValue: item.id))
        default:       break
        }
    }

    func unequipItem(_ item: InventoryItemDisplay) {
        switch item.itemDetails {
        case .weapon:  session.unequipWeapon(id: OwnedItemID(rawValue: item.id))
        case .shield:  session.unequipShield()
        case .armor:   session.unequipArmor(id: OwnedItemID(rawValue: item.id))
        case .jewelry: session.unequipJewelry(id: OwnedItemID(rawValue: item.id))
        default:       break
        }
    }

}

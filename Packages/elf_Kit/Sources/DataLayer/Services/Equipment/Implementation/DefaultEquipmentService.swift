//
//  DefaultEquipmentService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.01.26.
//

import Foundation

/// Default implementation of `EquipmentService`.
/// Reads inventory directly from the player store and mutates only `EquippedItems`
/// via `GameStateService.modifyEquipment`, so observation is scoped to the
/// equipped slot and unrelated views (e.g. farm skills) are not invalidated.
@MainActor
public final class DefaultEquipmentService: EquipmentService {

    // MARK: - Dependencies

    private let gameService: any GameStateService

    // MARK: - Initialization

    public init(gameService: any GameStateService) {
        self.gameService = gameService
    }

    // MARK: - Weapon

    public func equipWeapon(id: UUID) {
        guard let weapon = gameService.player.inventory.weapons.first(where: { $0.id == id }),
              let weaponItem = weapon.item as? WeaponItem else { return }

        gameService.modifyEquipment { equipped in
            let currentConfig = equipped.weapons

            switch weaponItem.handUse {
            case .both:
                equipped.weapons = .twoHanded(weapon: weapon)
            case .primary:
                if let existingShield = currentConfig.shield {
                    equipped.weapons = .oneHandedWithShield(weapon: weapon, shield: existingShield)
                } else {
                    equipped.weapons = .oneHanded(weapon: weapon)
                }
            case .secondary:
                equipped.weapons = .dualWield(primary: currentConfig.weapon, secondary: weapon)
            }
        }
    }

    public func unequipWeapon(id: UUID) {
        gameService.modifyEquipment { equipped in
            guard case .dualWield(let primary, let secondary) = equipped.weapons else { return }

            if primary.id == id {
                equipped.weapons = .oneHanded(weapon: secondary)
            } else {
                equipped.weapons = .oneHanded(weapon: primary)
            }
        }
    }

    // MARK: - Shield

    public func equipShield(id: UUID) {
        guard let shield = gameService.player.inventory.shields.first(where: { $0.id == id }) else { return }

        gameService.modifyEquipment { equipped in
            switch equipped.weapons {
            case .oneHanded(let weapon), .oneHandedWithShield(let weapon, _):
                equipped.weapons = .oneHandedWithShield(weapon: weapon, shield: shield)
            case .twoHanded, .dualWield:
                break
            }
        }
    }

    public func unequipShield() {
        gameService.modifyEquipment { equipped in
            if case .oneHandedWithShield(let weapon, _) = equipped.weapons {
                equipped.weapons = .oneHanded(weapon: weapon)
            }
        }
    }

    // MARK: - Armor

    public func equipArmor(id: UUID) {
        let inventory = gameService.player.inventory

        if let robe = inventory.robes.first(where: { $0.id == id }) {
            gameService.modifyEquipment { equipped in
                equipped.shirt = robe
            }
            return
        }

        guard let armor = inventory.armor.first(where: { $0.id == id }),
              let defenseItem = armor.item as? DefenseItem,
              let slot = Self.determineArmorSlot(from: defenseItem) else { return }

        gameService.modifyEquipment { equipped in
            Self.setArmor(armor, slot: slot, on: &equipped)
        }
    }

    public func unequipArmor(id: UUID) {
        gameService.modifyEquipment { equipped in
            if equipped.shirt?.id == id {
                equipped.shirt = nil
            } else if equipped.helmet?.id == id {
                Self.setArmor(nil, slot: .helmet, on: &equipped)
            } else if equipped.gloves?.id == id {
                Self.setArmor(nil, slot: .gloves, on: &equipped)
            } else if equipped.shoes?.id == id {
                Self.setArmor(nil, slot: .shoes, on: &equipped)
            } else if equipped.upperBody?.id == id {
                Self.setArmor(nil, slot: .upperBody, on: &equipped)
            } else if equipped.bottomBody?.id == id {
                Self.setArmor(nil, slot: .bottomBody, on: &equipped)
            }
        }
    }

    // MARK: - Jewelry

    public func equipJewelry(id: UUID) {
        guard let jewelry = gameService.player.inventory.jewelry.first(where: { $0.id == id }) else { return }

        gameService.modifyEquipment { equipped in
            if equipped.ring == nil {
                equipped.ring = jewelry
            } else if equipped.necklace == nil {
                equipped.necklace = jewelry
            } else if equipped.earrings == nil {
                equipped.earrings = jewelry
            } else {
                equipped.ring = jewelry
            }
        }
    }

    public func unequipJewelry(id: UUID) {
        gameService.modifyEquipment { equipped in
            if equipped.ring?.id == id {
                equipped.ring = nil
            } else if equipped.necklace?.id == id {
                equipped.necklace = nil
            } else if equipped.earrings?.id == id {
                equipped.earrings = nil
            }
        }
    }

    // MARK: - Private Helpers

    private static func determineArmorSlot(from defenseItem: DefenseItem) -> ArmorSlot? {
        if defenseItem.protectParts.contains(.head) {
            return .helmet
        } else if defenseItem.protectParts.contains(.leftHand) || defenseItem.protectParts.contains(.rightHand) {
            return .gloves
        } else if defenseItem.protectParts.contains(.legs) {
            return .shoes
        } else if defenseItem.protectParts.contains(.body) {
            return .upperBody
        }
        return nil
    }

    private static func setArmor(_ armor: ElfDefenseItem?, slot: ArmorSlot, on equipped: inout EquippedItems) {
        switch slot {
        case .helmet:
            equipped.helmet = armor
        case .gloves:
            equipped.gloves = armor
        case .shoes:
            equipped.shoes = armor
        case .upperBody:
            equipped.upperBody = armor
        case .bottomBody:
            equipped.bottomBody = armor
        }
    }
}

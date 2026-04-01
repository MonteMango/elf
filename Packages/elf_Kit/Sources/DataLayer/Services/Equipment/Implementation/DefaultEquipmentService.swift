//
//  DefaultEquipmentService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.01.26.
//

import Foundation

/// Default implementation of EquipmentService
/// Uses GameStateService.modifyPlayer for atomic read-modify-write operations
public final class DefaultEquipmentService: EquipmentService {

    // MARK: - Dependencies

    private let gameService: any GameStateService

    // MARK: - Initialization

    public init(gameService: any GameStateService) {
        self.gameService = gameService
    }

    // MARK: - Weapon

    public func equipWeapon(id: UUID) async {
        await gameService.modifyPlayer { player in
            guard let weapon = player.inventory.weapons.first(where: { $0.id == id }),
                  let weaponItem = weapon.item as? WeaponItem else { return }

            let currentConfig = player.equipped.weapons

            switch weaponItem.handUse {
            case .both:
                player.equipped.weapons = .twoHanded(weapon: weapon)
            case .primary:
                if let existingShield = currentConfig.shield {
                    player.equipped.weapons = .oneHandedWithShield(weapon: weapon, shield: existingShield)
                } else {
                    player.equipped.weapons = .oneHanded(weapon: weapon)
                }
            case .secondary:
                player.equipped.weapons = .dualWield(primary: currentConfig.weapon, secondary: weapon)
            }
        }
    }

    public func unequipWeapon(id: UUID) async {
        await gameService.modifyPlayer { player in
            guard case .dualWield(let primary, let secondary) = player.equipped.weapons else { return }

            if primary.id == id {
                player.equipped.weapons = .oneHanded(weapon: secondary)
            } else {
                player.equipped.weapons = .oneHanded(weapon: primary)
            }
        }
    }

    // MARK: - Shield

    public func equipShield(id: UUID) async {
        await gameService.modifyPlayer { player in
            guard let shield = player.inventory.shields.first(where: { $0.id == id }) else { return }

            switch player.equipped.weapons {
            case .oneHanded(let weapon), .oneHandedWithShield(let weapon, _):
                player.equipped.weapons = .oneHandedWithShield(weapon: weapon, shield: shield)
            case .twoHanded, .dualWield:
                break
            }
        }
    }

    public func unequipShield() async {
        await gameService.modifyPlayer { player in
            if case .oneHandedWithShield(let weapon, _) = player.equipped.weapons {
                player.equipped.weapons = .oneHanded(weapon: weapon)
            }
        }
    }

    // MARK: - Armor

    public func equipArmor(id: UUID) async {
        await gameService.modifyPlayer { player in
            if let robe = player.inventory.robes.first(where: { $0.id == id }) {
                player.equipped.shirt = robe
                return
            }

            guard let armor = player.inventory.armor.first(where: { $0.id == id }),
                  let defenseItem = armor.item as? DefenseItem,
                  let slot = Self.determineArmorSlot(from: defenseItem) else { return }

            Self.setArmor(armor, slot: slot, on: &player)
        }
    }

    public func unequipArmor(id: UUID) async {
        await gameService.modifyPlayer { player in
            let equipped = player.equipped

            if equipped.shirt?.id == id {
                player.equipped.shirt = nil
            } else if equipped.helmet?.id == id {
                Self.setArmor(nil, slot: .helmet, on: &player)
            } else if equipped.gloves?.id == id {
                Self.setArmor(nil, slot: .gloves, on: &player)
            } else if equipped.shoes?.id == id {
                Self.setArmor(nil, slot: .shoes, on: &player)
            } else if equipped.upperBody?.id == id {
                Self.setArmor(nil, slot: .upperBody, on: &player)
            } else if equipped.bottomBody?.id == id {
                Self.setArmor(nil, slot: .bottomBody, on: &player)
            }
        }
    }

    // MARK: - Jewelry

    public func equipJewelry(id: UUID) async {
        await gameService.modifyPlayer { player in
            guard let jewelry = player.inventory.jewelry.first(where: { $0.id == id }) else { return }

            let equipped = player.equipped

            if equipped.ring == nil {
                player.equipped.ring = jewelry
            } else if equipped.necklace == nil {
                player.equipped.necklace = jewelry
            } else if equipped.earrings == nil {
                player.equipped.earrings = jewelry
            } else {
                player.equipped.ring = jewelry // Replace ring by default
            }
        }
    }

    public func unequipJewelry(id: UUID) async {
        await gameService.modifyPlayer { player in
            let equipped = player.equipped

            if equipped.ring?.id == id {
                player.equipped.ring = nil
            } else if equipped.necklace?.id == id {
                player.equipped.necklace = nil
            } else if equipped.earrings?.id == id {
                player.equipped.earrings = nil
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

    private static func setArmor(_ armor: ElfDefenseItem?, slot: ArmorSlot, on player: inout ElfInfo) {
        switch slot {
        case .helmet:
            player.equipped.helmet = armor
        case .gloves:
            player.equipped.gloves = armor
        case .shoes:
            player.equipped.shoes = armor
        case .upperBody:
            player.equipped.upperBody = armor
        case .bottomBody:
            player.equipped.bottomBody = armor
        }
    }
}

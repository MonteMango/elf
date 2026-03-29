//
//  DefaultEquipmentService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.01.26.
//

import Foundation

/// Default implementation of EquipmentService
/// Uses GameService for state access and low-level mutations
// TODO: - Race condition: each method reads game state and then writes back in separate actor hops.
// Between read and write another Task can modify the state (e.g. two concurrent equipArmor calls
// both see the same free slot). Fix by either making this an actor, or moving equip logic
// into DefaultGameService where mutations are serialized.
public final class DefaultEquipmentService: EquipmentService {

    // MARK: - Dependencies

    private let gameService: GameService

    // MARK: - Initialization

    public init(gameService: GameService) {
        self.gameService = gameService
    }

    // MARK: - Weapon

    public func equipWeapon(id: UUID) async {
        let game = await gameService.game
        let player = game.houses[game.playerHouseIndex].members[game.playerMemberIndex]

        guard let weapon = player.inventory.weapons.first(where: { $0.id == id }),
              let weaponItem = weapon.item as? WeaponItem else { return }

        let currentConfig = player.equipped.weapons

        switch weaponItem.handUse {
        case .both:
            await gameService.setWeaponConfiguration(.twoHanded(weapon: weapon))
        case .primary:
            if let existingShield = currentConfig.shield {
                await gameService.setWeaponConfiguration(.oneHandedWithShield(weapon: weapon, shield: existingShield))
            } else {
                await gameService.setWeaponConfiguration(.oneHanded(weapon: weapon))
            }
        case .secondary:
            await gameService.setWeaponConfiguration(.dualWield(primary: currentConfig.weapon, secondary: weapon))
        }
    }

    public func unequipWeapon(id: UUID) async {
        let game = await gameService.game
        let player = game.houses[game.playerHouseIndex].members[game.playerMemberIndex]

        guard case .dualWield(let primary, let secondary) = player.equipped.weapons else { return }

        if primary.id == id {
            await gameService.setWeaponConfiguration(.oneHanded(weapon: secondary))
        } else {
            await gameService.setWeaponConfiguration(.oneHanded(weapon: primary))
        }
    }

    // MARK: - Shield

    public func equipShield(id: UUID) async {
        let game = await gameService.game
        let player = game.houses[game.playerHouseIndex].members[game.playerMemberIndex]

        guard let shield = player.inventory.shields.first(where: { $0.id == id }) else { return }

        switch player.equipped.weapons {
        case .oneHanded(let weapon), .oneHandedWithShield(let weapon, _):
            await gameService.setWeaponConfiguration(.oneHandedWithShield(weapon: weapon, shield: shield))
        case .twoHanded, .dualWield:
            break // Cannot equip shield with two-handed or dual-wield
        }
    }

    public func unequipShield() async {
        let game = await gameService.game
        let player = game.houses[game.playerHouseIndex].members[game.playerMemberIndex]

        if case .oneHandedWithShield(let weapon, _) = player.equipped.weapons {
            await gameService.setWeaponConfiguration(.oneHanded(weapon: weapon))
        }
    }

    // MARK: - Armor

    public func equipArmor(id: UUID) async {
        let game = await gameService.game
        let player = game.houses[game.playerHouseIndex].members[game.playerMemberIndex]

        if let robe = player.inventory.robes.first(where: { $0.id == id }) {
            await gameService.equipShirt(robe)
            return
        }

        guard let armor = player.inventory.armor.first(where: { $0.id == id }),
              let defenseItem = armor.item as? DefenseItem,
              let slot = determineArmorSlot(from: defenseItem) else { return }

        await gameService.equipArmor(armor, slot: slot)
    }

    private func determineArmorSlot(from defenseItem: DefenseItem) -> ArmorSlot? {
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

    public func unequipArmor(id: UUID) async {
        let game = await gameService.game
        let player = game.houses[game.playerHouseIndex].members[game.playerMemberIndex]
        let equipped = player.equipped

        if equipped.shirt?.id == id {
            await gameService.equipShirt(nil)
        } else if equipped.helmet?.id == id {
            await gameService.equipArmor(nil, slot: .helmet)
        } else if equipped.gloves?.id == id {
            await gameService.equipArmor(nil, slot: .gloves)
        } else if equipped.shoes?.id == id {
            await gameService.equipArmor(nil, slot: .shoes)
        } else if equipped.upperBody?.id == id {
            await gameService.equipArmor(nil, slot: .upperBody)
        } else if equipped.bottomBody?.id == id {
            await gameService.equipArmor(nil, slot: .bottomBody)
        }
    }

    // MARK: - Jewelry

    public func equipJewelry(id: UUID) async {
        let game = await gameService.game
        let player = game.houses[game.playerHouseIndex].members[game.playerMemberIndex]

        guard let jewelry = player.inventory.jewelry.first(where: { $0.id == id }) else { return }

        let equipped = player.equipped

        if equipped.ring == nil {
            await gameService.equipJewelry(jewelry, slot: .ring)
        } else if equipped.necklace == nil {
            await gameService.equipJewelry(jewelry, slot: .necklace)
        } else if equipped.earrings == nil {
            await gameService.equipJewelry(jewelry, slot: .earrings)
        } else {
            await gameService.equipJewelry(jewelry, slot: .ring) // Replace ring by default
        }
    }

    public func unequipJewelry(id: UUID) async {
        let game = await gameService.game
        let player = game.houses[game.playerHouseIndex].members[game.playerMemberIndex]
        let equipped = player.equipped

        if equipped.ring?.id == id {
            await gameService.equipJewelry(nil, slot: .ring)
        } else if equipped.necklace?.id == id {
            await gameService.equipJewelry(nil, slot: .necklace)
        } else if equipped.earrings?.id == id {
            await gameService.equipJewelry(nil, slot: .earrings)
        }
    }
}

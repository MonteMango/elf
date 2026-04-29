//
//  DefaultEquipmentService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.01.26.
//

import Dependencies
import Foundation

/// Default implementation of `EquipmentService`.
/// Reads inventory directly from the player store and writes `player.equipped`
/// on `PlayerStore`. Per-property `@Observable` tracking scopes invalidation to
/// the equipped slot — unrelated views (e.g. farm skills) are not re-evaluated.
@MainActor
public final class DefaultEquipmentService: EquipmentService {

    // MARK: - Dependencies (snapshotted at init)

    private let gameService: any GameStateService
    private let itemsRepository: any ItemsRepository

    // MARK: - Initialization

    public init(gameService: any GameStateService) {
        @Dependency(\.itemsRepository) var itemsRepository
        self.itemsRepository = itemsRepository

        self.gameService = gameService
    }

    // MARK: - Weapon

    public func equipWeapon(id: UUID) {
        guard let weapon = gameService.player.inventory.weapons.first(where: { $0.id == id }),
              let weaponItem = weapon.item as? WeaponItem else { return }

        var equipped = gameService.player.equipped
        let currentConfig = equipped.weapons

        switch weaponItem.handUse {
        case .both:
            guard let twoHanded = ElfTwoHandedWeaponItem(weapon: weapon) else { return }
            equipped.weapons = .twoHanded(weapon: twoHanded)

        case .oneHand:
            guard let oneHanded = ElfOneHandedWeaponItem(weapon: weapon) else { return }
            switch currentConfig {
            case .oneHanded(let existingPrimary):
                // Player already has a one-hander: equipping another one-hander auto-promotes
                // the configuration to dual-wield with the new weapon in the off-hand slot.
                equipped.weapons = .dualWield(primary: existingPrimary, secondary: oneHanded)
            case .oneHandedWithShield(_, let shield):
                equipped.weapons = .oneHandedWithShield(weapon: oneHanded, shield: shield)
            case .dualWield(_, let secondary):
                equipped.weapons = .dualWield(primary: oneHanded, secondary: secondary)
            case .twoHanded:
                equipped.weapons = .oneHanded(weapon: oneHanded)
            }
        }
        gameService.player.equipped = equipped
    }

    public func equipOffhandWeapon(id: UUID) {
        guard let weapon = gameService.player.inventory.weapons.first(where: { $0.id == id }),
              let weaponItem = weapon.item as? WeaponItem,
              weaponItem.handUse == .oneHand,
              let oneHanded = ElfOneHandedWeaponItem(weapon: weapon) else { return }

        var equipped = gameService.player.equipped
        switch equipped.weapons {
        case .oneHanded(let primary), .dualWield(let primary, _):
            equipped.weapons = .dualWield(primary: primary, secondary: oneHanded)
        case .oneHandedWithShield(let primary, _):
            equipped.weapons = .dualWield(primary: primary, secondary: oneHanded)
        case .twoHanded:
            // Two-handed is auto-unequipped. There is no main-hand to pair with, so the new
            // weapon becomes the sole one-hander — preserves "at least one weapon equipped".
            equipped.weapons = .oneHanded(weapon: oneHanded)
        }
        gameService.player.equipped = equipped
    }

    public func unequipWeapon(id: UUID) {
        var equipped = gameService.player.equipped
        guard case .dualWield(let primary, let secondary) = equipped.weapons else { return }

        if primary.id == id {
            equipped.weapons = .oneHanded(weapon: secondary)
        } else {
            equipped.weapons = .oneHanded(weapon: primary)
        }
        gameService.player.equipped = equipped
    }

    // MARK: - Shield

    public func equipShield(id: UUID) {
        guard let shield = gameService.player.inventory.shields.first(where: { $0.id == id }) else { return }

        var equipped = gameService.player.equipped
        switch equipped.weapons {
        case .oneHanded(let weapon), .oneHandedWithShield(let weapon, _):
            equipped.weapons = .oneHandedWithShield(weapon: weapon, shield: shield)
        case .dualWield(let primary, _):
            // Off-hand weapon is auto-unequipped to make room for the shield.
            equipped.weapons = .oneHandedWithShield(weapon: primary, shield: shield)
        case .twoHanded:
            // No one-handed primary to pair with: the type system forbids `.oneHandedWithShield`
            // without a one-handed weapon. Player must first swap the two-hander for a one-hander.
            return
        }
        gameService.player.equipped = equipped
    }

    public func unequipShield() {
        var equipped = gameService.player.equipped
        guard case .oneHandedWithShield(let weapon, _) = equipped.weapons else { return }
        equipped.weapons = .oneHanded(weapon: weapon)
        gameService.player.equipped = equipped
    }

    // MARK: - Armor

    public func equipArmor(id: UUID) {
        let inventory = gameService.player.inventory

        if let robe = inventory.robes.first(where: { $0.id == id }) {
            var equipped = gameService.player.equipped
            equipped.shirt = robe
            gameService.player.equipped = equipped
            return
        }

        guard let armor = inventory.armor.first(where: { $0.id == id }),
              let defenseItem = armor.item as? DefenseItem,
              let slot = itemsRepository.armorSlot(for: defenseItem.id) else { return }

        var equipped = gameService.player.equipped
        Self.setArmor(armor, slot: slot, on: &equipped)
        gameService.player.equipped = equipped
    }

    public func unequipArmor(id: UUID) {
        var equipped = gameService.player.equipped
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
        } else {
            return
        }
        gameService.player.equipped = equipped
    }

    // MARK: - Jewelry

    public func equipJewelry(id: UUID) {
        guard let jewelry = gameService.player.inventory.jewelry.first(where: { $0.id == id }) else { return }

        var equipped = gameService.player.equipped
        if equipped.ring == nil {
            equipped.ring = jewelry
        } else if equipped.necklace == nil {
            equipped.necklace = jewelry
        } else if equipped.earrings == nil {
            equipped.earrings = jewelry
        } else {
            equipped.ring = jewelry
        }
        gameService.player.equipped = equipped
    }

    public func unequipJewelry(id: UUID) {
        var equipped = gameService.player.equipped
        if equipped.ring?.id == id {
            equipped.ring = nil
        } else if equipped.necklace?.id == id {
            equipped.necklace = nil
        } else if equipped.earrings?.id == id {
            equipped.earrings = nil
        } else {
            return
        }
        gameService.player.equipped = equipped
    }

    // MARK: - Private Helpers

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

//
//  ElfEquipmentService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.01.26.
//

import Dependencies
import Foundation

/// Default implementation of `EquipmentService`.
///
/// Stateless, pure transforms over `EquippedItems`. Each method reads from the
/// supplied `equipped` (and `inventory` where a lookup is needed) and returns a
/// new `EquippedItems`; the caller (`GameSession`) writes the result back into
/// `state.player.equipped`, which `@Observable` propagates to SwiftUI.
public final class ElfEquipmentService: EquipmentService {

    // MARK: - Dependencies

    // Resolved lazily on purpose: `itemsRepository` has a `fatalError` live
    // value (it is bootstrapped from async-loaded game data) and is only needed
    // by `equipArmor`. Reading it through a computed property defers resolution
    // to first use, so constructing the service — e.g. when `GameSession`
    // resolves it at init — never forces the repository unless an armor slot is
    // actually touched. A computed property (rather than a stored `@Dependency`)
    // also keeps the type's `Sendable` conformance free of mutable stored state.
    private var itemsRepository: any ItemsRepository {
        @Dependency(\.itemsRepository) var itemsRepository
        return itemsRepository
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Weapon

    public func equipWeapon(id: OwnedItemID, in equipped: EquippedItems, inventory: ElfInventory) -> EquippedItems {
        guard let weapon = inventory.weapons.first(where: { $0.id == id }),
              let weaponItem = weapon.item as? WeaponItem else { return equipped }

        var equipped = equipped
        let currentConfig = equipped.weapons

        switch weaponItem.handUse {
        case .both:
            guard let twoHanded = ElfTwoHandedWeaponItem(weapon: weapon) else { return equipped }
            equipped.weapons = .twoHanded(weapon: twoHanded)

        case .oneHand:
            guard let oneHanded = ElfOneHandedWeaponItem(weapon: weapon) else { return equipped }
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
        return equipped
    }

    public func equipOffhandWeapon(id: OwnedItemID, in equipped: EquippedItems, inventory: ElfInventory) -> EquippedItems {
        guard let weapon = inventory.weapons.first(where: { $0.id == id }),
              let weaponItem = weapon.item as? WeaponItem,
              weaponItem.handUse == .oneHand,
              let oneHanded = ElfOneHandedWeaponItem(weapon: weapon) else { return equipped }

        var equipped = equipped
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
        return equipped
    }

    public func unequipWeapon(id: OwnedItemID, in equipped: EquippedItems) -> EquippedItems {
        var equipped = equipped
        guard case .dualWield(let primary, let secondary) = equipped.weapons else { return equipped }

        if primary.id == id {
            equipped.weapons = .oneHanded(weapon: secondary)
        } else {
            equipped.weapons = .oneHanded(weapon: primary)
        }
        return equipped
    }

    // MARK: - Shield

    public func equipShield(id: OwnedItemID, in equipped: EquippedItems, inventory: ElfInventory) -> EquippedItems {
        guard let shield = inventory.shields.first(where: { $0.id == id }) else { return equipped }

        var equipped = equipped
        switch equipped.weapons {
        case .oneHanded(let weapon), .oneHandedWithShield(let weapon, _):
            equipped.weapons = .oneHandedWithShield(weapon: weapon, shield: shield)
        case .dualWield(let primary, _):
            // Off-hand weapon is auto-unequipped to make room for the shield.
            equipped.weapons = .oneHandedWithShield(weapon: primary, shield: shield)
        case .twoHanded:
            // No one-handed primary to pair with: the type system forbids `.oneHandedWithShield`
            // without a one-handed weapon. Player must first swap the two-hander for a one-hander.
            return equipped
        }
        return equipped
    }

    public func unequipShield(in equipped: EquippedItems) -> EquippedItems {
        var equipped = equipped
        guard case .oneHandedWithShield(let weapon, _) = equipped.weapons else { return equipped }
        equipped.weapons = .oneHanded(weapon: weapon)
        return equipped
    }

    // MARK: - Armor

    public func equipArmor(id: OwnedItemID, in equipped: EquippedItems, inventory: ElfInventory) -> EquippedItems {
        if let robe = inventory.robes.first(where: { $0.id == id }) {
            var equipped = equipped
            equipped.shirt = robe
            return equipped
        }

        guard let armor = inventory.armor.first(where: { $0.id == id }),
              let defenseItem = armor.item as? DefenseItem,
              let slot = itemsRepository.armorSlot(for: defenseItem.id) else { return equipped }

        var equipped = equipped
        setArmor(armor, slot: slot, on: &equipped)
        return equipped
    }

    public func unequipArmor(id: OwnedItemID, in equipped: EquippedItems) -> EquippedItems {
        var equipped = equipped
        if equipped.shirt?.id == id {
            equipped.shirt = nil
        } else if equipped.helmet?.id == id {
            setArmor(nil, slot: .helmet, on: &equipped)
        } else if equipped.gloves?.id == id {
            setArmor(nil, slot: .gloves, on: &equipped)
        } else if equipped.shoes?.id == id {
            setArmor(nil, slot: .shoes, on: &equipped)
        } else if equipped.upperBody?.id == id {
            setArmor(nil, slot: .upperBody, on: &equipped)
        } else if equipped.bottomBody?.id == id {
            setArmor(nil, slot: .bottomBody, on: &equipped)
        }
        return equipped
    }

    // MARK: - Jewelry

    public func equipJewelry(id: OwnedItemID, in equipped: EquippedItems, inventory: ElfInventory) -> EquippedItems {
        guard let jewelry = inventory.jewelry.first(where: { $0.id == id }) else { return equipped }

        var equipped = equipped
        if equipped.ring == nil {
            equipped.ring = jewelry
        } else if equipped.necklace == nil {
            equipped.necklace = jewelry
        } else if equipped.earrings == nil {
            equipped.earrings = jewelry
        } else {
            equipped.ring = jewelry
        }
        return equipped
    }

    public func unequipJewelry(id: OwnedItemID, in equipped: EquippedItems) -> EquippedItems {
        var equipped = equipped
        if equipped.ring?.id == id {
            equipped.ring = nil
        } else if equipped.necklace?.id == id {
            equipped.necklace = nil
        } else if equipped.earrings?.id == id {
            equipped.earrings = nil
        }
        return equipped
    }

    // MARK: - Private Helpers

    private func setArmor(_ armor: ElfDefenseItem?, slot: ArmorSlot, on equipped: inout EquippedItems) {
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

//
//  EquipmentService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.01.26.
//

import Foundation

/// Protocol for managing player equipment.
/// Handles weapon, armor, shield, and jewelry equipping logic.
/// Main-actor-isolated: mutates the player via `GameStateService.modifyEquipment`.
@MainActor
public protocol EquipmentService: AnyObject {

    // MARK: - Weapon

    /// Equips a weapon from inventory through the main weapons tab. Behaviour depends on
    /// the weapon's `handUse` and the current configuration:
    /// - **Two-handed weapon**: replaces both hands (any shield or off-hand weapon is dropped).
    /// - **One-handed weapon** with current `.oneHanded`: auto-promotes to dual-wield with the
    ///   existing weapon as main hand and the new weapon in the off-hand slot.
    /// - **One-handed weapon** with current `.oneHandedWithShield`: replaces the main-hand
    ///   weapon, keeping the shield.
    /// - **One-handed weapon** with current `.dualWield`: replaces the main-hand weapon,
    ///   keeping the off-hand weapon.
    /// - **One-handed weapon** with current `.twoHanded`: replaces the two-hander (drops it).
    /// Use `equipOffhandWeapon(id:)` to explicitly target the off-hand slot.
    func equipWeapon(id: OwnedItemID)

    /// Equips a one-handed weapon from inventory into the **off-hand** slot, forming a dual-wield.
    /// - If a shield is currently equipped, it is auto-unequipped.
    /// - If a two-handed weapon is currently equipped, it is auto-unequipped and the new weapon
    ///   becomes the sole main-hand weapon.
    /// - No-op when the supplied weapon is two-handed.
    func equipOffhandWeapon(id: OwnedItemID)

    /// Unequips weapon (only works for the off-hand weapon in dual-wield mode)
    func unequipWeapon(id: OwnedItemID)

    // MARK: - Shield

    /// Equips shield from inventory (only if current weapon config allows)
    func equipShield(id: OwnedItemID)

    /// Unequips current shield
    func unequipShield()

    // MARK: - Armor

    /// Equips armor from inventory, auto-determining slot by protectParts
    func equipArmor(id: OwnedItemID)

    /// Unequips armor by finding which slot contains it
    func unequipArmor(id: OwnedItemID)

    // MARK: - Jewelry

    /// Equips jewelry from inventory, auto-finding first free slot
    func equipJewelry(id: OwnedItemID)

    /// Unequips jewelry by finding which slot contains it
    func unequipJewelry(id: OwnedItemID)
}

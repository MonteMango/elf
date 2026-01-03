//
//  EquipmentService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.01.26.
//

import Foundation

/// Protocol for managing player equipment
/// Handles weapon, armor, shield, and jewelry equipping logic
@MainActor
public protocol EquipmentService: AnyObject {

    // MARK: - Weapon

    /// Equips weapon from inventory, auto-determining configuration based on handUse
    func equipWeapon(id: UUID)

    /// Unequips weapon (only works for secondary in dual-wield mode)
    func unequipWeapon(id: UUID)

    /// Returns true if any weapon can be unequipped (dual-wield mode only)
    func canUnequipWeapon() -> Bool

    // MARK: - Shield

    /// Equips shield from inventory (only if current weapon config allows)
    func equipShield(id: UUID)

    /// Unequips current shield
    func unequipShield()

    // MARK: - Armor

    /// Equips armor from inventory, auto-determining slot by protectParts
    func equipArmor(id: UUID)

    /// Unequips armor by finding which slot contains it
    func unequipArmor(id: UUID)

    // MARK: - Jewelry

    /// Equips jewelry from inventory, auto-finding first free slot
    func equipJewelry(id: UUID)

    /// Unequips jewelry by finding which slot contains it
    func unequipJewelry(id: UUID)
}

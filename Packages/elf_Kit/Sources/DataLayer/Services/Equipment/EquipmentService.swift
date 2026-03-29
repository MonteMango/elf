//
//  EquipmentService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.01.26.
//

import Foundation

/// Protocol for managing player equipment
/// Handles weapon, armor, shield, and jewelry equipping logic
public protocol EquipmentService: AnyObject {

    // MARK: - Weapon

    /// Equips weapon from inventory, auto-determining configuration based on handUse
    func equipWeapon(id: UUID) async

    /// Unequips weapon (only works for secondary in dual-wield mode)
    func unequipWeapon(id: UUID) async

    // MARK: - Shield

    /// Equips shield from inventory (only if current weapon config allows)
    func equipShield(id: UUID) async

    /// Unequips current shield
    func unequipShield() async

    // MARK: - Armor

    /// Equips armor from inventory, auto-determining slot by protectParts
    func equipArmor(id: UUID) async

    /// Unequips armor by finding which slot contains it
    func unequipArmor(id: UUID) async

    // MARK: - Jewelry

    /// Equips jewelry from inventory, auto-finding first free slot
    func equipJewelry(id: UUID) async

    /// Unequips jewelry by finding which slot contains it
    func unequipJewelry(id: UUID) async
}

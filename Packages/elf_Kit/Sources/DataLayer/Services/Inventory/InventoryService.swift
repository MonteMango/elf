//
//  InventoryService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Service for managing inventory operations
///
/// Extracted from ElfInventory mutating methods to separate business logic from data models.
/// All operations return new inventory instances (immutable pattern).
public protocol InventoryService: Sendable {

    // MARK: - Add Equipment

    /// Adds a weapon to inventory
    /// - Returns: New inventory with the weapon added
    func addWeapon(_ weapon: ElfWeaponItem, to inventory: ElfInventory) -> ElfInventory

    /// Adds a shield to inventory
    /// - Returns: New inventory with the shield added
    func addShield(_ shield: ElfShieldItem, to inventory: ElfInventory) -> ElfInventory

    /// Adds an armor piece to inventory
    /// - Returns: New inventory with the armor added
    func addArmor(_ armor: ElfDefenseItem, to inventory: ElfInventory) -> ElfInventory

    /// Adds a robe to inventory
    /// - Returns: New inventory with the robe added
    func addRobe(_ robe: ElfRobeItem, to inventory: ElfInventory) -> ElfInventory

    /// Adds jewelry to inventory
    /// - Returns: New inventory with the jewelry added
    func addJewelry(_ jewelry: ElfJewelryItem, to inventory: ElfInventory) -> ElfInventory

    // MARK: - Add Materials

    /// Adds material to inventory. Stacks with existing material of same ID.
    /// - Returns: New inventory with the material added/stacked
    func addMaterial(id: UUID, quantity: Int, to inventory: ElfInventory) -> ElfInventory
}

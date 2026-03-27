//
//  CraftService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Craft Service Protocol

public protocol CraftService: Sendable {
    /// Check whether the player has enough materials to craft
    func canCraft(recipe: Recipe, inventory: ElfInventory) async -> Bool

    /// Get missing ingredients list
    func getMissingIngredients(recipe: Recipe, inventory: ElfInventory) async -> [MissingIngredient]

    /// Deduct materials from inventory. Returns updated inventory.
    func deductMaterials(recipe: Recipe, from inventory: ElfInventory) async -> ElfInventory
}

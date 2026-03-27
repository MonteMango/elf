//
//  DefaultCraftService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class DefaultCraftService: CraftService {

    public init() {}

    public func canCraft(recipe: Recipe, inventory: ElfInventory) async -> Bool {
        await getMissingIngredients(recipe: recipe, inventory: inventory).isEmpty
    }

    public func getMissingIngredients(recipe: Recipe, inventory: ElfInventory) async -> [MissingIngredient] {
        recipe.ingredients.compactMap { ingredient in
            let available = inventory.materials.first(where: { $0.id == ingredient.itemId })?.quantity ?? 0
            guard available < ingredient.amount else { return nil }
            return MissingIngredient(
                itemId: ingredient.itemId,
                required: ingredient.amount,
                available: available
            )
        }
    }

    public func deductMaterials(recipe: Recipe, from inventory: ElfInventory) async -> ElfInventory {
        // Aggregate required amounts by itemId to handle duplicate ingredients
        var requiredAmounts: [UUID: Int] = [:]
        for ingredient in recipe.ingredients {
            requiredAmounts[ingredient.itemId, default: 0] += ingredient.amount
        }

        var newInventory = inventory
        for (itemId, totalAmount) in requiredAmounts {
            if let index = newInventory.materials.firstIndex(where: { $0.id == itemId }) {
                newInventory.materials[index].quantity -= totalAmount
                if newInventory.materials[index].quantity <= 0 {
                    newInventory.materials.remove(at: index)
                }
            }
        }
        return newInventory
    }
}

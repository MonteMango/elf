//
//  Recipe.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Recipe

public struct Recipe: Decodable, Sendable, Identifiable {
    public let id: RecipeID
    public let resultItemId: ItemID
    public let category: RecipeCategory
    public let ingredients: [RecipeIngredient]

    public init(
        id: RecipeID,
        resultItemId: ItemID,
        category: RecipeCategory,
        ingredients: [RecipeIngredient]
    ) {
        self.id = id
        self.resultItemId = resultItemId
        self.category = category
        self.ingredients = ingredients
    }
}

// MARK: - Recipes Data (JSON root)

public struct RecipesData: Decodable, Sendable {
    public let version: String
    public let weapons: [Recipe]
    public let armor: [Recipe]

    public init(version: String = "1.0", weapons: [Recipe] = [], armor: [Recipe] = []) {
        self.version = version
        self.weapons = weapons
        self.armor = armor
    }
}

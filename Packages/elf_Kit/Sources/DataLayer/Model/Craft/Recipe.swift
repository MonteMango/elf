//
//  Recipe.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Recipe

public struct Recipe: Decodable, Sendable, Identifiable {
    public let id: UUID
    public let resultItemId: UUID
    public let category: RecipeCategory
    public let ingredients: [RecipeIngredient]

    public init(
        id: UUID,
        resultItemId: UUID,
        category: RecipeCategory,
        ingredients: [RecipeIngredient]
    ) {
        self.id = id
        self.resultItemId = resultItemId
        self.category = category
        self.ingredients = ingredients
    }
}

// MARK: - Recipe Ingredient

public struct RecipeIngredient: Decodable, Sendable {
    public let itemId: UUID
    public let type: IngredientType
    public let amount: Int

    public init(itemId: UUID, type: IngredientType, amount: Int) {
        self.itemId = itemId
        self.type = type
        self.amount = amount
    }
}

// MARK: - Ingredient Type

public enum IngredientType: String, Decodable, Sendable {
    case material
    case ore
}

// MARK: - Recipe Category

public enum RecipeCategory: String, Decodable, CaseIterable, Sendable {
    case weapon
    case armor
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

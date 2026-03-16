//
//  ElfRecipeRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class ElfRecipeRepository: RecipeRepository {

    private let recipesData: RecipesData
    private let recipeLookup: [UUID: Recipe]

    public init(dataLoader: DataLoader = ElfDataLoader()) {
        let data: Data
        do {
            data = try dataLoader.loadRecipesData()
        } catch {
            print("Warning: Could not load Recipes.json, using empty data: \(error)")
            data = Data("{\"version\":\"1.0\",\"weapons\":[],\"armor\":[]}".utf8)
        }

        let decoded: RecipesData
        do {
            decoded = try JSONDecoder().decode(RecipesData.self, from: data)
        } catch {
            print("Warning: Failed to decode recipes, using empty fallback: \(error)")
            decoded = RecipesData()
        }

        self.recipesData = decoded

        var lookup: [UUID: Recipe] = [:]
        for recipe in decoded.weapons { lookup[recipe.id] = recipe }
        for recipe in decoded.armor { lookup[recipe.id] = recipe }
        self.recipeLookup = lookup
    }

    public func getRecipes(for category: RecipeCategory) -> [Recipe] {
        switch category {
        case .weapon: return recipesData.weapons
        case .armor: return recipesData.armor
        }
    }

    public func getRecipe(id: UUID) -> Recipe? {
        recipeLookup[id]
    }
}

extension ElfRecipeRepository: @unchecked Sendable {}

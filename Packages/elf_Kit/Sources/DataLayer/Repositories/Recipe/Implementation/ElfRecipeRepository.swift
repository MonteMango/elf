//
//  ElfRecipeRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class ElfRecipeRepository: RecipeRepository {

    private let recipesData: RecipesData
    private let items: [Recipe]
    private let lookup: [UUID: Recipe]

    public init(recipesData: RecipesData) {
        self.recipesData = recipesData

        var lookup: [UUID: Recipe] = [:]
        for recipe in recipesData.weapons { lookup[recipe.id] = recipe }
        for recipe in recipesData.armor { lookup[recipe.id] = recipe }

        self.lookup = lookup
        self.items = recipesData.weapons + recipesData.armor
    }

    public func getAll() -> [Recipe] { items }

    public func getById(id: UUID) -> Recipe? { lookup[id] }

    public func recipes(for category: RecipeCategory) -> [Recipe] {
        switch category {
        case .weapon: return recipesData.weapons
        case .armor: return recipesData.armor
        }
    }
}

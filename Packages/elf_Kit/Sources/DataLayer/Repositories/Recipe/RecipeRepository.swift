//
//  RecipeRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public protocol RecipeRepository: Sendable {
    /// Get all recipes for a given category
    func getRecipes(for category: RecipeCategory) -> [Recipe]

    /// Get a single recipe by ID
    func getRecipe(id: UUID) -> Recipe?
}

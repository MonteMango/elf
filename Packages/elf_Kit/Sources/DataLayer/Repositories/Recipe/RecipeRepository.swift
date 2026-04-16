//
//  RecipeRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public protocol RecipeRepository: Repository<Recipe> {

    /// Get all recipes for a given category.
    func recipes(for category: RecipeCategory) -> [Recipe]
}

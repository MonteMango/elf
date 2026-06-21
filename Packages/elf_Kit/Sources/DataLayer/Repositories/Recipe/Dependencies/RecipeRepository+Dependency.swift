//
//  RecipeRepository+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var recipeRepository: any RecipeRepository {
        get { self[RecipeRepositoryKey.self] }
        set { self[RecipeRepositoryKey.self] = newValue }
    }
}

private enum RecipeRepositoryKey: DependencyKey {
    static var liveValue: any RecipeRepository {
        fatalError("RecipeRepository must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It is sourced from async-loaded GameDataRepository.")
    }
}

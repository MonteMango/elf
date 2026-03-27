//
//  DefaultCharacterNameSuggestionService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 26.11.25.
//

import Foundation

/// Default implementation of CharacterNameSuggestionService
public struct DefaultCharacterNameSuggestionService: CharacterNameSuggestionService {

    private enum Constants {
        static let suggestedNames = [
            "Asuna Yuuki",
            "Kirito",
            "Leafa",
            "Sinon",
            "Alice",
            "Eugeo",
            "Yui",
            "Klein"
        ]
        static let fallbackName = "Hero"
    }

    public init() {}

    public func generateRandomName() async -> String {
        return Constants.suggestedNames.randomElement() ?? Constants.fallbackName
    }
}

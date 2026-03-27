//
//  CharacterNameSuggestionService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 26.11.25.
//

import Foundation

/// Service for providing character name suggestions
public protocol CharacterNameSuggestionService: Sendable {
    /// Generate a random character name
    /// - Returns: Random character name
    func generateRandomName() async -> String
}

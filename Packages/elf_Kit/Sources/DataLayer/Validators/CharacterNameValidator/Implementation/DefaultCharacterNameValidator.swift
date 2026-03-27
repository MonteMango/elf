//
//  DefaultCharacterNameValidator.swift
//  elf_Kit
//
//  Created by Claude on 26.11.25.
//

import Foundation

/// Default implementation of character name validation
public struct DefaultCharacterNameValidator: CharacterNameValidator {

    private enum Constants {
        static let minLength = 2
        static let maxLength = 30
    }

    public init() {}

    public func validate(_ name: String) async -> NameValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespaces)

        // Empty name is not valid
        guard !trimmed.isEmpty else {
            return .invalid(reason: "Name cannot be empty")
        }

        // Check minimum length
        guard trimmed.count >= Constants.minLength else {
            return .invalid(reason: "Name must be at least \(Constants.minLength) characters")
        }

        // Check maximum length
        guard trimmed.count <= Constants.maxLength else {
            return .invalid(reason: "Name must be at most \(Constants.maxLength) characters")
        }

        // Check for valid characters (letters and spaces only)
        let allowedCharacters = CharacterSet.letters.union(.whitespaces)
        guard trimmed.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return .invalid(reason: "Name should contain only letters and spaces")
        }

        return .valid
    }
}
 

//
//  CharacterNameValidator.swift
//  elf_Kit
//
//  Created by Claude on 25.11.25.
//

import Foundation

/// Result of character name validation
public enum NameValidationResult: Sendable, Equatable {
    case valid
    case invalid(reason: String)

    public var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }

    public var errorMessage: String? {
        if case .invalid(let reason) = self {
            return reason
        }
        return nil
    }
}

/// Protocol for validating character names
public protocol CharacterNameValidator: Sendable {
    func validate(_ name: String) async -> NameValidationResult
}

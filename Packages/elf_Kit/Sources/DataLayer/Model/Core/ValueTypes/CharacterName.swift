//
//  CharacterName.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// A validated character name (2-30 characters, letters and spaces only).
///
/// This type ensures that once created, a CharacterName is always valid.
/// Use the `parse` method to create instances from raw user input.
///
/// ## Usage
/// ```swift
/// let result = CharacterName.parse("Legolas")
/// switch result {
/// case .success(let name):
///     createCharacter(name: name)
/// case .failure(let error):
///     showError(error)
/// }
/// ```
public struct CharacterName: Sendable, Hashable, Equatable {

    /// The validated name string
    public let value: String

    /// Minimum allowed length
    public static let minLength = 2

    /// Maximum allowed length
    public static let maxLength = 30

    /// Private initializer — use `parse` to create instances
    private init(validated: String) {
        self.value = validated
    }

    /// Parses a raw string into a validated CharacterName.
    ///
    /// - Parameter raw: The raw input string
    /// - Returns: A Result containing either the validated name or a validation error
    public static func parse(_ raw: String) -> Result<CharacterName, NameValidationError> {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            return .failure(.empty)
        }

        guard trimmed.count >= minLength else {
            return .failure(.tooShort(minimum: minLength))
        }

        guard trimmed.count <= maxLength else {
            return .failure(.tooLong(maximum: maxLength))
        }

        let allowedCharacters = CharacterSet.letters.union(.whitespaces)
        guard trimmed.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return .failure(.invalidCharacters)
        }

        // Check for multiple consecutive spaces
        if trimmed.contains("  ") {
            return .failure(.invalidCharacters)
        }

        return .success(CharacterName(validated: trimmed))
    }

    /// Creates a CharacterName unsafely (for internal use only).
    /// Use only when the name is guaranteed to be valid (e.g., from persistent storage).
    ///
    /// - Parameter value: The name string (must be valid!)
    /// - Returns: A CharacterName
    public static func unsafeCreate(_ value: String) -> CharacterName {
        CharacterName(validated: value)
    }
}

// MARK: - Validation Error

/// Errors that can occur when validating a character name
public enum NameValidationError: Error, Equatable, Sendable, LocalizedError {
    /// The name is empty
    case empty

    /// The name is shorter than the minimum length
    case tooShort(minimum: Int)

    /// The name is longer than the maximum length
    case tooLong(maximum: Int)

    /// The name contains invalid characters
    case invalidCharacters

    public var errorDescription: String? {
        switch self {
        case .empty:
            return "Name cannot be empty"
        case .tooShort(let minimum):
            return "Name must be at least \(minimum) characters"
        case .tooLong(let maximum):
            return "Name must be at most \(maximum) characters"
        case .invalidCharacters:
            return "Name can only contain letters and spaces"
        }
    }
}

// MARK: - Codable

extension CharacterName: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)

        // For backward compatibility, accept any non-empty string from storage
        // but still validate new input
        if raw.isEmpty {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Character name cannot be empty"
                )
            )
        }

        // Use unsafeCreate for data from storage (assumed valid)
        self = CharacterName.unsafeCreate(raw)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - CustomStringConvertible

extension CharacterName: CustomStringConvertible {
    public var description: String {
        value
    }
}

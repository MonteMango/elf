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

    /// Private initializer — use `unsafeCreate` to create instances
    private init(validated: String) {
        self.value = validated
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

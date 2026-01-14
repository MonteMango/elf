//
//  CharacterBuilder.swift
//  elf_Kit
//
//  Created by Claude on 25.11.25.
//

import Foundation

/// Errors that can occur during character building
public enum CharacterBuilderError: Error, Sendable, Equatable {
    case missingAppearance
    case missingName
    case invalidName(String)
    case missingFightStyle
    case attributeLoadingFailed

    public var localizedDescription: String {
        switch self {
        case .missingAppearance:
            return "Character appearance must be selected"
        case .missingName:
            return "Character name must be provided"
        case .invalidName(let reason):
            return reason
        case .missingFightStyle:
            return "Fight style must be selected"
        case .attributeLoadingFailed:
            return "Failed to load character attributes"
        }
    }
}

/// Protocol for building PlayerCharacter with validation
/// Note: @MainActor because it holds mutable state used in character creation flow
@MainActor
public protocol CharacterBuilder {
    func setAppearance(_ appearance: CharacterAppearance)

    func setName(_ name: String)

    func setFightStyle(_ fightStyle: FightStyle)

    func reset()

    func build(
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes
    ) throws -> PlayerCharacter
}

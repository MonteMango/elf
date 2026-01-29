//
//  CharacterBuilder.swift
//  elf_Kit
//
//  Created by Claude on 25.11.25.
//

import Foundation

/// Errors that can occur during character building
enum CharacterBuilderError: Error, Sendable, Equatable {
    case missingAppearance
    case missingName
    case missingFightStyle

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

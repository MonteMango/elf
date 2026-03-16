//
//  DefaultCharacterBuilder.swift
//  elf_Kit
//
//  Created by Claude on 26.11.25.
//

import Foundation

/// Default implementation of CharacterBuilder
public final class DefaultCharacterBuilder: CharacterBuilder {

    // MARK: - Private Properties

    private var appearance: CharacterAppearance?
    private var name: String = ""
    private var fightStyle: FightStyle?

    // MARK: - Initialization

    public init() {}

    // MARK: - Builder Methods

    public func setAppearance(_ appearance: CharacterAppearance) {
        self.appearance = appearance
    }

    public func setName(_ name: String) {
        self.name = name
    }

    public func setFightStyle(_ fightStyle: FightStyle) {
        self.fightStyle = fightStyle
    }

    /// Reset builder to initial state
    public func reset() {
        appearance = nil
        name = ""
        fightStyle = nil
    }

    // MARK: - Build Method

    /// Build and validate character with provided attributes
    /// - Parameters:
    ///   - fightStyleAttributes: Attributes based on selected fight style
    ///   - randomLevelAttributes: Random attributes for the starting level
    /// - Returns: Fully constructed PlayerCharacter
    /// - Throws: CharacterBuilderError if validation fails
    public func build(
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes
    ) throws -> PlayerCharacter {
        // Validate appearance
        guard let appearance = appearance else {
            throw CharacterBuilderError.missingAppearance
        }

        // Validate name (basic check - full validation happens in ViewModel)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw CharacterBuilderError.missingName
        }

        // Validate fight style
        guard let fightStyle = fightStyle else {
            throw CharacterBuilderError.missingFightStyle
        }

        // Build character
        return PlayerCharacter(
            name: trimmedName,
            appearance: appearance,
            fightStyle: fightStyle,
            level: GameMechanicsConstants.startingLevel,
            fightStyleAttributes: fightStyleAttributes,
            randomLevelAttributes: randomLevelAttributes
        )
    }
}

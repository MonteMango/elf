//
//  CharacterBuilder.swift
//  elf_Kit
//
//  Created by Claude on 25.11.25.
//

import Foundation

/// Protocol for building PlayerCharacter with validation
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

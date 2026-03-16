//
//  CharacterBuilder.swift
//  elf_Kit
//
//  Created by Claude on 25.11.25.
//

import Foundation

/// Protocol for building PlayerCharacter with validation
public protocol CharacterBuilder: Sendable {
    func setAppearance(_ appearance: CharacterAppearance) async

    func setName(_ name: String) async

    func setFightStyle(_ fightStyle: FightStyle) async

    func reset() async

    func build(
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes
    ) async throws -> PlayerCharacter
}

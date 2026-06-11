//
//  PlayerCharacter.swift
//  elf_Kit
//
//  Created by Claude on 23.11.25.
//

import Foundation

/// Represents a player's created character
public struct PlayerCharacter: Sendable, Identifiable {
    public let id: PlayerCharacterID
    public let name: String
    public let appearance: CharacterAppearance
    public let fightStyle: FightStyle
    public let level: Int16

    /// Base attributes from fight style
    public let fightStyleAttributes: HeroAttributes

    /// Random attributes gained per level
    public let randomLevelAttributes: HeroAttributes

    /// Total attributes (fight style + random)
    public var totalAttributes: HeroAttributes {
        HeroAttributes(
            hitPoints: fightStyleAttributes.hitPoints + randomLevelAttributes.hitPoints,
            manaPoints: fightStyleAttributes.manaPoints + randomLevelAttributes.manaPoints,
            agility: fightStyleAttributes.agility + randomLevelAttributes.agility,
            strength: fightStyleAttributes.strength + randomLevelAttributes.strength,
            power: fightStyleAttributes.power + randomLevelAttributes.power,
            instinct: fightStyleAttributes.instinct + randomLevelAttributes.instinct,
            endurance: fightStyleAttributes.endurance + randomLevelAttributes.endurance
        )
    }

    public init(
        id: PlayerCharacterID = PlayerCharacterID(),
        name: String,
        appearance: CharacterAppearance,
        fightStyle: FightStyle,
        level: Int16 = 1,
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes
    ) {
        self.id = id
        self.name = name
        self.appearance = appearance
        self.fightStyle = fightStyle
        self.level = level
        self.fightStyleAttributes = fightStyleAttributes
        self.randomLevelAttributes = randomLevelAttributes
    }
}

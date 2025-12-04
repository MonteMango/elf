//
//  DefaultElfInfoFactory.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.12.25.
//

import Foundation

/// Default implementation of ElfInfoFactory
public final class DefaultElfInfoFactory: ElfInfoFactory {

    // MARK: - Dependencies

    private let attributeService: AttributeService

    // MARK: - Constants

    private let aiNames = [
        "Aria", "Luna", "Stella", "Nova", "Aurora",
        "Celeste", "Lyra", "Iris", "Fern", "Willow",
        "Sage", "Ivy", "Rose", "Lily", "Violet",
        "Jade", "Pearl", "Ruby", "Amber", "Crystal"
    ]

    private let availableFightStyles: [FightStyle] = [.dodge, .crit, .def]

    // MARK: - Initialization

    public init(attributeService: AttributeService) {
        self.attributeService = attributeService
    }

    // MARK: - ElfInfoFactory

    public func create(from character: PlayerCharacter) -> ElfInfo {
        ElfInfo(
            id: character.id,
            name: character.name,
            imageName: character.appearance.imageName,
            fightStyle: character.fightStyle,
            level: character.level,
            currentExp: 0,
            expToNextLevel: 100,
            fightStyleAttributes: character.fightStyleAttributes,
            randomLevelAttributes: character.randomLevelAttributes,
            currentHP: character.totalAttributes.hitPoints,
            currentMP: character.totalAttributes.manaPoints,
            equippedItems: [:],
            reputation: 0
        )
    }

    public func createRandomAI(level: Int16) async -> ElfInfo {
        let fightStyle = availableFightStyles.randomElement()!

        // Use AttributeService like in BattleSetup
        let fightStyleAttributes = await attributeService.getAllFightStyleAttributes(
            for: fightStyle,
            at: level
        )
        let randomLevelAttributes = await attributeService.getAllRandomLevelAttributes(
            for: level
        )

        let totalHP = fightStyleAttributes.hitPoints + randomLevelAttributes.hitPoints
        let totalMP = fightStyleAttributes.manaPoints + randomLevelAttributes.manaPoints

        return ElfInfo(
            name: aiNames.randomElement()!,
            imageName: "elf_ai_\(Int.random(in: 1...10))",
            fightStyle: fightStyle,
            level: level,
            currentExp: 0,
            expToNextLevel: 100 * Int(level),
            fightStyleAttributes: fightStyleAttributes,
            randomLevelAttributes: randomLevelAttributes,
            currentHP: totalHP,
            currentMP: totalMP
        )
    }
}

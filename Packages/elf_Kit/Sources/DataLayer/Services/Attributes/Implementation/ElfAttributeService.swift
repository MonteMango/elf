//
//  ElfAttributeService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 01.11.24.
//

import Dependencies
import Foundation

public final class ElfAttributeService: AttributeService {

    private let itemsRepository: any ItemsRepository
    private let randomizer: any AttributeRandomizer

    public init() {
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.attributeRandomizer) var randomizer
        self.itemsRepository = itemsRepository
        self.randomizer = randomizer
    }

    public func getAllFightStyleAttributes(for fightStyle: FightStyle, at level: Int16) -> HeroAttributes {
        // Base HP 80 + 5 per level applies to every fight style (so a lvl-12
        // hero starts a battle with 140 HP). Per-style differentiation is
        // expressed via offensive/defensive stats, not HP scaling.
        let hitPoints = Attribute(80 + 5 * level)

        switch fightStyle {
        case .crit:
            return HeroAttributes(
                hitPoints: hitPoints,
                manaPoints: 20,
                agility: 0,
                strength: Attribute(1 * level),
                power: Attribute(4 * level),
                instinct: Attribute(1 * level),
                endurance: 0
            )

        case .def:
            return HeroAttributes(
                hitPoints: hitPoints,
                manaPoints: 20,
                agility: 0,
                strength: Attribute(1 * level),
                power: 0,
                instinct: Attribute(2 * level),
                endurance: Attribute(3 * level)
            )

        case .dodge:
            return HeroAttributes(
                hitPoints: hitPoints,
                manaPoints: 20,
                agility: Attribute(4 * level),
                strength: Attribute(1 * level),
                power: 0,
                instinct: Attribute(1 * level),
                endurance: 0
            )
        }
    }

    public func getRandomLevelAttributes() -> HeroAttributes {
        var attributes = HeroAttributes()
        var pointsAssigned = 0

        while pointsAssigned < 4 {
            let attribute = randomizer.nextAttribute()

            switch attribute {
            case "hitPoints":
                attributes.hitPoints += 3
            case "manaPoints":
                attributes.manaPoints += 3
            case "agility":
                attributes.agility += 1
            case "strength":
                attributes.strength += 1
            case "power":
                attributes.power += 1
            case "instinct":
                attributes.instinct += 1
            case "endurance":
                attributes.endurance += 1
            default:
                break
            }

            pointsAssigned += 1
        }

        return attributes
    }

    public func getAllRandomLevelAttributes(for level: Int16) -> HeroAttributes {
        // Sequential execution - getRandomLevelAttributes is a lightweight operation
        var totalAttributes = HeroAttributes()
        for _ in 1...level {
            let attributes = getRandomLevelAttributes()
            totalAttributes.hitPoints += attributes.hitPoints
            totalAttributes.manaPoints += attributes.manaPoints
            totalAttributes.agility += attributes.agility
            totalAttributes.strength += attributes.strength
            totalAttributes.power += attributes.power
            totalAttributes.instinct += attributes.instinct
            totalAttributes.endurance += attributes.endurance
        }
        return totalAttributes
    }

    public func getAllItemsAttributes(for itemIds: [UUID]) -> HeroAttributes {
        var aggregatedAttributes = HeroAttributes()
        for itemId in itemIds {
            if let item = itemsRepository.getHeroItem(itemId) {
                aggregatedAttributes = aggregateItemAttributes(item: item, existingAttributes: aggregatedAttributes)
            }
        }
        return aggregatedAttributes
    }

    private func aggregateItemAttributes(item: Item, existingAttributes: HeroAttributes) -> HeroAttributes {
        var updatedAttributes = existingAttributes
        if let strength = item.strength {
            updatedAttributes.strength += strength
        }
        if let agility = item.agility {
            updatedAttributes.agility += agility
        }
        if let power = item.power {
            updatedAttributes.power += power
        }
        if let instinct = item.instinct {
            updatedAttributes.instinct += instinct
        }
        if let endurance = item.endurance {
            updatedAttributes.endurance += endurance
        }
        if let hitPoints = item.hitPoints {
            updatedAttributes.hitPoints += hitPoints
        }
        if let manaPoints = item.manaPoints {
            updatedAttributes.manaPoints += manaPoints
        }
        return updatedAttributes
    }
}

//
//  ElfAttributeService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 01.11.24.
//

import Foundation

public final class ElfAttributeService: AttributeService {

    private let itemsRepository: ItemsRepository
    private let randomizer: AttributeRandomizer

    public init(itemsRepository: ItemsRepository, randomizer: AttributeRandomizer = ElfAttributeRandomizer()) {
        self.itemsRepository = itemsRepository
        self.randomizer = randomizer
    }

    public func getAllFightStyleAttributes(for fightStyle: FightStyle, at level: Int16) async -> HeroAttributes {
        switch fightStyle {
        case .crit:
            return HeroAttributes(
                hitPoints: 80,
                manaPoints: 20,
                agility: 0,
                strength: Attribute(1 * level),
                power: Attribute(4 * level),
                instinct: Attribute(1 * level)
            )

        case .def:
            return HeroAttributes(
                hitPoints: Attribute(80 + (2 * level)),
                manaPoints: 20,
                agility: 0,
                strength: Attribute(2 * level),
                power: 0,
                instinct: Attribute(2 * level)
            )

        case .dodge:
            return HeroAttributes(
                hitPoints: 80,
                manaPoints: 20,
                agility: Attribute(4 * level),
                strength: Attribute(1 * level),
                power: 0,
                instinct: Attribute(1 * level)
            )
        }
    }

    public func getRandomLevelAttributes() async -> HeroAttributes {
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
            default:
                break
            }

            pointsAssigned += 1
        }

        return attributes
    }

    public func getAllRandomLevelAttributes(for level: Int16) async -> HeroAttributes {
        // Sequential execution - getRandomLevelAttributes is a lightweight operation
        // No benefit from parallelization, avoids thread overhead
        var totalAttributes = HeroAttributes()
        for _ in 1...level {
            let attributes = await getRandomLevelAttributes()
            totalAttributes.hitPoints += attributes.hitPoints
            totalAttributes.manaPoints += attributes.manaPoints
            totalAttributes.agility += attributes.agility
            totalAttributes.strength += attributes.strength
            totalAttributes.power += attributes.power
            totalAttributes.instinct += attributes.instinct
        }
        return totalAttributes
    }

    public func getAllItemsAttributes(for itemIds: [UUID]) async -> HeroAttributes {
        var aggregatedAttributes = HeroAttributes()
        for itemId in itemIds {
            if let item = await itemsRepository.getHeroItem(itemId) {
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
        if let hitPoints = item.hitPoints {
            updatedAttributes.hitPoints += hitPoints
        }
        if let manaPoints = item.manaPoints {
            updatedAttributes.manaPoints += manaPoints
        }
        return updatedAttributes
    }
}

// MARK: - Sendable Conformance
// Thread-safe: All stored properties are immutable (let) after initialization.
// Dependencies: ItemsRepository is a Sendable protocol, AttributeRandomizer is stateless.
extension ElfAttributeService: @unchecked Sendable {}

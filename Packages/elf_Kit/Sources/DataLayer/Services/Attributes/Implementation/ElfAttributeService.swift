//
//  ElfAttributeService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 01.11.24.
//

import Combine
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
            var attributes = HeroAttributes()
            attributes.hitPoints = 100
            attributes.manaPoints = 20
            attributes.agility = 0
            attributes.instinct = 2 * level
            attributes.power = 4 * level
            attributes.strength = 0
            return attributes
            
        case .def:
            var attributes = HeroAttributes()
            attributes.hitPoints = 100 + (5 * level)
            attributes.manaPoints = 20
            attributes.agility = 0
            attributes.instinct = 3 * level
            attributes.power = 0
            attributes.strength = 2 * level
            return attributes
            
        case .dodge:
            var attributes = HeroAttributes()
            attributes.hitPoints = 100
            attributes.manaPoints = 20
            attributes.agility = 4 * level
            attributes.instinct = 2 * level
            attributes.power = 0
            attributes.strength = 0
            return attributes
        }
    }
    
    public func getRandomLevelAttributes() async -> HeroAttributes {
        var attributes = HeroAttributes()
        var pointsAssigned = 0

        while pointsAssigned < 4 {
            let attribute = randomizer.nextAttribute()

            switch attribute {
            case "hitPoints":
                attributes.hitPoints += 5
            case "manaPoints":
                attributes.manaPoints += 5
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
    
    public func getAllItemsAttrbutes(for itemIds: [UUID]) async -> HeroAttributes {
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
extension ElfAttributeService: @unchecked Sendable {}

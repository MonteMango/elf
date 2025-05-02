//
//  ElfAttributeService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 01.11.24.
//

import Combine
import GameplayKit

public final class ElfAttributeService: AttributeService {
    
    private let itemsRepository: ItemsRepository
    private var heroItems: HeroItems?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(itemsRepository: ItemsRepository) {
        self.itemsRepository = itemsRepository
        
        itemsRepository.heroItemsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.heroItems, on: self)
            .store(in: &cancellables)
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
        
        // Установим "веса" для каждого атрибута в соответствии с требуемыми вероятностями
        let weightedAttributes = [
            "hitPoints", "hitPoints",               // 10%
            "manaPoints", "manaPoints",             // 10%
            "agility", "agility", "agility", "agility",  // 20%
            "strength", "strength", "strength", "strength", // 20%
            "power", "power", "power", "power",     // 20%
            "instinct", "instinct", "instinct", "instinct" // 20%
        ]
        
        // Используем `GKRandomDistribution` для случайного выбора по индексам
        let distribution = GKShuffledDistribution(lowestValue: 0, highestValue: weightedAttributes.count - 1)
        
        var pointsAssigned = 0
        while pointsAssigned < 4 {
            let randomIndex = distribution.nextInt()
            let attribute = weightedAttributes[randomIndex]
            
            // Применяем правило увеличения на 5 для hitPoints и manaPoints
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
    
    
    public func getAllRandomLevelAttributes(for level: Int16) async -> [Int16: HeroAttributes] {
        var levelAttributes: [Int16: HeroAttributes] = [:]
        
        for currentLevel in 1...level {
            // Генерируем атрибуты для текущего уровня
            let attributes = await getRandomLevelAttributes()
            // Сохраняем в словарь с текущим уровнем как ключом
            levelAttributes[Int16(currentLevel)] = attributes
        }
        
        return levelAttributes
    }
    
    public func getAllItemsAttrbutes(for itemIds: [HeroItemType: UUID?]) async -> HeroAttributes {
        var aggregatedAttributes = HeroAttributes()
        
        // Loop through all item types
        for (itemType, itemId) in itemIds {
            // Skip the item if its ID is nil
            guard let itemId = itemId else { continue }
            
            // Find the corresponding item from the heroItems repository based on itemType
            switch itemType {
            case .helmet:
                if let helmet = heroItems?.helmets.first(where: { $0.id == itemId }) {
                    aggregatedAttributes = aggregateItemAttributes(item: helmet, existingAttributes: aggregatedAttributes)
                }
            case .gloves:
                if let gloves = heroItems?.gloves.first(where: { $0.id == itemId }) {
                    aggregatedAttributes = aggregateItemAttributes(item: gloves, existingAttributes: aggregatedAttributes)
                }
            case .shoes:
                if let shoes = heroItems?.shoes.first(where: { $0.id == itemId }) {
                    aggregatedAttributes = aggregateItemAttributes(item: shoes, existingAttributes: aggregatedAttributes)
                }
            case .upperBody:
                if let upperBody = heroItems?.upperBodies.first(where: { $0.id == itemId }) {
                    aggregatedAttributes = aggregateItemAttributes(item: upperBody, existingAttributes: aggregatedAttributes)
                }
            case .bottomBody:
                if let bottomBody = heroItems?.bottomBodies.first(where: { $0.id == itemId }) {
                    aggregatedAttributes = aggregateItemAttributes(item: bottomBody, existingAttributes: aggregatedAttributes)
                }
            case .shirt:
                if let shirt = heroItems?.robes.first(where: { $0.id == itemId }) {
                    aggregatedAttributes = aggregateItemAttributes(item: shirt, existingAttributes: aggregatedAttributes)
                }
            case .ring:
                if let ring = heroItems?.rings.first(where: { $0.id == itemId }) {
                    aggregatedAttributes = aggregateItemAttributes(item: ring, existingAttributes: aggregatedAttributes)
                }
            case .necklace:
                if let necklace = heroItems?.necklaces.first(where: { $0.id == itemId }) {
                    aggregatedAttributes = aggregateItemAttributes(item: necklace, existingAttributes: aggregatedAttributes)
                }
            case .earrings:
                if let earrings = heroItems?.earrings.first(where: { $0.id == itemId }) {
                    aggregatedAttributes = aggregateItemAttributes(item: earrings, existingAttributes: aggregatedAttributes)
                }
            case .weapons:
                if let weapon = heroItems?.weapons.first(where: { $0.id == itemId }) {
                    aggregatedAttributes = aggregateItemAttributes(item: weapon, existingAttributes: aggregatedAttributes)
                }
            case .shields:
                if let shield = heroItems?.shields.first(where: { $0.id == itemId }) {
                    aggregatedAttributes = aggregateItemAttributes(item: shield, existingAttributes: aggregatedAttributes)
                }
            }
        }
        
        return aggregatedAttributes
    }
    
    private func aggregateItemAttributes(item: Item, existingAttributes: HeroAttributes) -> HeroAttributes {
        var updatedAttributes = existingAttributes
        
        // Aggregate the item attributes into existingAttributes
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

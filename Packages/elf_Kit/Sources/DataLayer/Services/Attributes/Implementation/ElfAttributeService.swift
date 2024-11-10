//
//  ElfAttributeService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 01.11.24.
//

import GameplayKit

public final class ElfAttributeService: AttributeService {
    
    public init() {
        
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
}

//
//  ElfDamageService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Combine
import Foundation

public final class ElfDamageService: DamageService {
    
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
    
    public func getMinMaxStrengthDamage(_ strengthAttribute: Int16) async -> (minDmg: Int16, maxDmg: Int16)? {
        let dmgStrengthDistribution = await getStrengthDamageDistribution(for: strengthAttribute)
        guard
            let minDmg = dmgStrengthDistribution.values.first,
            let maxDmg = dmgStrengthDistribution.values.last
        else { return nil }
        
        return (minDmg: minDmg, maxDmg: maxDmg)
    }
    
    private func getStrengthDamageDistribution(for strength: Int16) async -> DamageDistribution {
        switch strength {
        case 1...6:
            return await distributionForStrength1to6(strength)
        case 7...11:
            return await distributionForStrwngth(strength, minArgument: 7, minRangeLength: 4)
        default:
            return DamageDistribution(values: [0], weights: [0])
        }
    }
    
    private func distributionForStrength1to6(_ strength: Int16) async -> DamageDistribution {
        switch strength {
        case 1:
            return DamageDistribution(values: [0, 1], weights: [2, 1])
        case 2:
            return DamageDistribution(values: [0, 1], weights: [2, 2])
        case 3:
            return DamageDistribution(values: [0, 1, 2], weights: [2, 2, 1])
        case 4:
            return DamageDistribution(values: [0, 1, 2], weights: [2, 2, 2])
        case 5:
            return DamageDistribution(values: [0, 1, 2, 3], weights: [2, 2, 2, 1])
        case 6:
            return DamageDistribution(values: [0, 1, 2, 3], weights: [2, 2, 2, 2])
        default:
            return DamageDistribution(values: [0], weights: [0])
        }
    }
    
    private func distributionForStrwngth(_ strength: Int16, minArgument: Int16, minRangeLength: Int) async -> DamageDistribution {
        let min = strength - minArgument
        let minWeigths = Array(repeating: 2, count: minRangeLength)
        let maxWeigths = [1] + minWeigths.dropLast() + [1]
        if strength % 2 == 0 {
            return DamageDistribution(
                values: [min, min + 1, min + 2, min + 3, min + 4], // length based on maxWeigths count
                weights: maxWeigths)
        } else {
            return DamageDistribution(
                values: [min + 1, min + 2, min + 3, min + 4], // // length based on minWeigths count
                weights: minWeigths)
        }
    }
}

public struct DamageDistribution {
    let values: [Int16]
    let weights: [Int]
}

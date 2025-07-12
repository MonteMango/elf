//
//  ElfStrengthDamageDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 11.07.25.
//

public final class ElfStrengthDamageDistributionStrategy: StrengthDamageDistributionStrategy {

    public init() {}

    public func distribution(for strength: Int16) -> DamageDistribution {
        if let template = predefinedDistributions[strength] {
            return DamageDistribution(values: template.values, weights: template.weights)
        } else {
            return distributionForExtendedStrength(strength)
        }
    }

    private func distributionForExtendedStrength(_ strength: Int16) -> DamageDistribution {
        let offset = strength - 26
        let baseValue = 12 + offset / 2

        if strength % 2 == 0 {
            return DamageDistribution(values: [baseValue, baseValue + 1], weights: [2, 2])
        } else {
            return DamageDistribution(values: [baseValue, baseValue + 1, baseValue + 2], weights: [1, 2, 1])
        }
    }

    private let predefinedDistributions: [Int16: (values: [Int16], weights: [Int])] = [
        1: ([0, 1], [2, 1]),
        2: ([0, 1], [2, 2]),
        3: ([0, 1, 2], [2, 2, 1]),
        4: ([0, 1, 2], [2, 2, 2]),
        5: ([0, 1, 2, 3], [2, 2, 2, 1]),
        6: ([0, 1, 2, 3], [2, 2, 2, 2]),
        7: ([0, 1, 2, 3, 4], [1, 2, 2, 2, 1]),
        8: ([1, 2, 3, 4], [2, 2, 2, 2]),
        9: ([1, 2, 3, 4, 5], [1, 2, 2, 2, 1]),
        10: ([2, 3, 4, 5], [2, 2, 2, 2]),
        11: ([2, 3, 4, 5, 6], [1, 2, 2, 2, 1]),
        12: ([3, 4, 5, 6], [2, 2, 2, 2]),
        13: ([4, 5, 6, 7], [2, 2, 2, 1]),
        14: ([5, 6, 7], [2, 2, 2]),
        15: ([5, 6, 7, 8], [1, 2, 2, 1]),
        16: ([6, 7, 8], [2, 2, 2]),
        17: ([6, 7, 8, 9], [1, 2, 2, 1]),
        18: ([7, 8, 9], [2, 2, 2]),
        19: ([7, 8, 9, 10], [1, 2, 2, 1]),
        20: ([8, 9, 10], [2, 2, 2]),
        21: ([8, 9, 10, 11], [1, 2, 2, 1]),
        22: ([9, 10, 11], [2, 2, 2]),
        23: ([9, 10, 11, 12], [1, 2, 2, 1]),
        24: ([10, 11, 12], [2, 2, 2]),
        25: ([11, 12, 13], [2, 2, 1])
    ]
}

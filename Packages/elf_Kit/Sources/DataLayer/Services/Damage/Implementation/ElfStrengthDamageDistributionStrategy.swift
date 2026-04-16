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
        // Pattern repeats every 8 steps starting from 45
        // Base value increases by 1 every 8 steps
        let offset = strength - 45
        let cyclePosition = Int(offset % 8)
        let baseValue: Int16 = 7 + Int16(offset / 8)

        switch cyclePosition {
        case 0: // like 45, 53, 61...
            return DamageDistribution(values: [baseValue, baseValue + 1], weights: [3, 3])
        case 1: // like 46, 54, 62...
            return DamageDistribution(values: [baseValue, baseValue + 1], weights: [2, 3])
        case 2: // like 47, 55, 63...
            return DamageDistribution(values: [baseValue, baseValue + 1], weights: [1, 3])
        case 3: // like 48, 56, 64...
            return DamageDistribution(values: [baseValue + 1], weights: [1])
        case 4: // like 49, 57, 65...
            return DamageDistribution(values: [baseValue + 1, baseValue + 2], weights: [3, 1])
        case 5: // like 50, 58, 66...
            return DamageDistribution(values: [baseValue + 1, baseValue + 2], weights: [3, 2])
        case 6: // like 51, 59, 67...
            return DamageDistribution(values: [baseValue + 1, baseValue + 2], weights: [3, 3])
        case 7: // like 52, 60, 68...
            return DamageDistribution(values: [baseValue + 2], weights: [1])
        default:
            return DamageDistribution(values: [baseValue], weights: [1])
        }
    }

//    private let predefinedDistributions: [Int16: (values: [Int16], weights: [Int])] = [
//        1: ([0, 1], [2, 1]),
//        2: ([0, 1], [2, 2]),
//        3: ([0, 1, 2], [2, 2, 1]),
//        4: ([0, 1, 2], [2, 2, 2]),
//        5: ([0, 1, 2, 3], [2, 2, 2, 1]),
//        6: ([0, 1, 2, 3], [2, 2, 2, 2]),
//        7: ([0, 1, 2, 3, 4], [1, 2, 2, 2, 1]),
//        8: ([1, 2, 3, 4], [2, 2, 2, 2]),
//        9: ([1, 2, 3, 4, 5], [1, 2, 2, 2, 1]),
//        10: ([2, 3, 4, 5], [2, 2, 2, 2]),
//        11: ([2, 3, 4, 5, 6], [1, 2, 2, 2, 1]),
//        12: ([3, 4, 5, 6], [2, 2, 2, 2]),
//        13: ([4, 5, 6, 7], [2, 2, 2, 1]),
//        14: ([5, 6, 7], [2, 2, 2]),
//        15: ([5, 6, 7, 8], [1, 2, 2, 1]),
//        16: ([6, 7, 8], [2, 2, 2]),
//        17: ([6, 7, 8, 9], [1, 2, 2, 1]),
//        18: ([7, 8, 9], [2, 2, 2]),
//        19: ([7, 8, 9, 10], [1, 2, 2, 1]),
//        20: ([8, 9, 10], [2, 2, 2]),
//        21: ([8, 9, 10, 11], [1, 2, 2, 1]),
//        22: ([9, 10, 11], [2, 2, 2]),
//        23: ([9, 10, 11, 12], [1, 2, 2, 1]),
//        24: ([10, 11, 12], [2, 2, 2]),
//        25: ([11, 12, 13], [2, 2, 1])
//    ]

//    private let predefinedDistributions: [Int16: (values: [Int16], weights: [Int])] = [
//        1: ([0, 1], [3, 1]),
//        2: ([0, 1], [3, 2]),
//        3: ([0, 1, 2], [3, 3, 1]),
//        4: ([0, 1, 2], [3, 3, 2]),
//        5: ([0, 1, 2, 3], [3, 3, 2, 1]),
//        6: ([0, 1, 2, 3], [3, 3, 2, 2]),
//        7: ([0, 1, 2, 3, 4], [2, 3, 3, 2, 1]),
//        8: ([1, 2, 3, 4], [3, 3, 3, 2]),
//        9: ([1, 2, 3, 4, 5], [2, 3, 3, 2, 1]),
//        10: ([2, 3, 4, 5], [3, 3, 2, 2]),
//        11: ([2, 3, 4, 5, 6], [2, 3, 3, 2, 1]),
//        12: ([3, 4, 5, 6], [3, 3, 3, 2]),
//        13: ([4, 5, 6, 7], [3, 3, 2, 1]),
//        14: ([5, 6, 7], [3, 3, 2]),
//        15: ([5, 6, 7, 8], [2, 3, 2, 1]),
//        16: ([6, 7, 8], [3, 3, 2]),
//        17: ([6, 7, 8, 9], [2, 3, 2, 1]),
//        18: ([7, 8, 9], [3, 3, 2]),
//        19: ([7, 8, 9, 10], [2, 3, 2, 1]),
//        20: ([8, 9, 10], [3, 3, 2]),
//        21: ([8, 9, 10, 11], [2, 3, 2, 1]),
//        22: ([9, 10, 11], [3, 3, 2]),
//        23: ([9, 10, 11, 12], [2, 3, 2, 1]),
//        24: ([10, 11, 12], [3, 3, 2]),
//        25: ([11, 12, 13], [3, 2, 1])
//    ]

    private let predefinedDistributions: [Int16: (values: [Int16], weights: [Int])] = [
        1: ([0, 1], [3, 1]),
        2: ([0, 1], [3, 2]),
        3: ([0, 1], [3, 3]),
        4: ([0, 1, 2], [3, 3, 1]),
        5: ([0, 1, 2], [3, 3, 2]),
        6: ([0, 1, 2], [3, 3, 3]),
        7: ([0, 1, 2, 3], [3, 3, 3, 1]),
        8: ([0, 1, 2, 3], [3, 3, 3, 2]),
        9: ([0, 1, 2, 3], [3, 3, 3, 3]),
        10: ([0, 1, 2, 3, 4], [3, 3, 3, 3, 1]),
        11: ([0, 1, 2, 3, 4], [3, 3, 3, 3, 2]),
        12: ([0, 1, 2, 3, 4], [3, 3, 3, 3, 3]),
        13: ([0, 1, 2, 3, 4], [2, 3, 3, 3, 3]),
        14: ([0, 1, 2, 3, 4], [1, 3, 3, 3, 3]),
        15: ([1, 2, 3, 4], [3, 3, 3, 3]),
        16: ([1, 2, 3, 4], [2, 3, 3, 3]),
        17: ([1, 2, 3, 4], [1, 3, 3, 3]),
        18: ([2, 3, 4], [3, 3, 3]),
        19: ([2, 3, 4, 5], [3, 3, 3, 1]),
        20: ([2, 3, 4, 5], [3, 3, 3, 2]),
        21: ([2, 3, 4, 5], [3, 3, 3, 3]),
        22: ([2, 3, 4, 5], [2, 3, 3, 3]),
        23: ([2, 3, 4, 5], [1, 3, 3, 3]),
        24: ([3, 4, 5], [3, 3, 3]),
        25: ([3, 4, 5, 6], [3, 3, 3, 1]),
        26: ([3, 4, 5, 6], [3, 3, 3, 2]),
        27: ([3, 4, 5, 6], [3, 3, 3, 3]),
        28: ([3, 4, 5, 6], [2, 3, 3, 3]),
        29: ([3, 4, 5, 6], [1, 3, 3, 3]),
        30: ([4, 5, 6], [3, 3, 3]),
        31: ([4, 5, 6], [2, 3, 3]),
        32: ([4, 5, 6], [1, 3, 3]),
        33: ([5, 6], [3, 3]),
        34: ([5, 6, 7], [3, 3, 1]),
        35: ([5, 6, 7], [3, 3, 2]),
        36: ([5, 6, 7], [3, 3, 3]),
        37: ([5, 6, 7], [2, 3, 3]),
        38: ([5, 6, 7], [1, 3, 3]),
        39: ([6, 7], [3, 3]),
        40: ([6, 7, 8], [3, 3, 1]),
        41: ([6, 7, 8], [3, 3, 2]),
        42: ([6, 7, 8], [3, 3, 3]),
        43: ([6, 7, 8], [2, 3, 3]),
        44: ([6, 7, 8], [1, 3, 3]),
        45: ([7, 8], [3, 3]),
        46: ([7, 8], [2, 3]),
        47: ([7, 8], [1, 3]),
        48: ([8], [1]),
        49: ([8, 9], [3, 1]),
        50: ([8, 9], [3, 2]),
        51: ([8, 9], [3, 3]),
        52: ([9], [1]),
    ]
}

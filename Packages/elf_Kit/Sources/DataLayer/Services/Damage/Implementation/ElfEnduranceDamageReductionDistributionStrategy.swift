//
//  ElfEnduranceDamageReductionDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

public final class ElfEnduranceDamageReductionDistributionStrategy: EnduranceDamageReductionDistributionStrategy {

    public init() {}

    public func distribution(for endurance: Int16) -> DamageDistribution {
        // Endurance < 1 → guaranteed zero reduction (mirrors Strength 0).
        guard endurance >= 1 else {
            return DamageDistribution(values: [0], weights: [1])
        }

        // endurance > 52 → clamp to row 52. Endurance that high is only
        // reachable through equipment / buffs, not levelling; no extended
        // cycle is defined for the 30%-of-Strength curve.
        let index = min(endurance, 52)

        if let template = predefinedDistributions[index] {
            return DamageDistribution(values: template.values, weights: template.weights)
        }
        // Defensive fallback — should be unreachable for index in 1...52.
        return DamageDistribution(values: [0], weights: [1])
    }

    // Hand-tuned so each row's mean ≈ 30% of the Strength row at the same
    // index. Errors stay within ±0.05 of target on def's actual levelling
    // values (endurance 9 / 18 / 27 / 36 at lvl 3 / 6 / 9 / 12).
    private let predefinedDistributions: [Int16: (values: [Int16], weights: [Int])] = [
        1: ([0, 1], [12, 1]),       // mean 0.077, target 0.075
        2: ([0, 1], [7, 1]),        // mean 0.125, target 0.12
        3: ([0, 1], [6, 1]),        // mean 0.143, target 0.15
        4: ([0, 1], [4, 1]),        // mean 0.200, target 0.21
        5: ([0, 1], [3, 1]),        // mean 0.250, target 0.26
        6: ([0, 1], [7, 3]),        // mean 0.300, target 0.30
        7: ([0, 1], [9, 5]),        // mean 0.357, target 0.36
        8: ([0, 1], [3, 2]),        // mean 0.400, target 0.41
        9: ([0, 1], [6, 5]),        // mean 0.455, target 0.45 — def L3
        10: ([0, 1], [1, 1]),        // mean 0.500, target 0.51
        11: ([0, 1], [4, 5]),        // mean 0.556, target 0.56
        12: ([0, 1], [2, 3]),        // mean 0.600, target 0.60
        13: ([0, 1], [3, 5]),        // mean 0.625, target 0.64
        14: ([0, 1], [3, 7]),        // mean 0.700, target 0.69
        15: ([0, 1, 2], [3, 4, 1]),  // mean 0.750, target 0.75
        16: ([0, 1], [1, 4]),        // mean 0.800, target 0.79
        17: ([0, 1], [1, 5]),        // mean 0.833, target 0.84
        18: ([0, 1, 2], [3, 5, 2]),  // mean 0.900, target 0.90 — def L6
        19: ([0, 1, 2], [3, 4, 3]),  // mean 1.000, target 0.96
        20: ([0, 1, 2], [3, 4, 3]),  // mean 1.000, target 1.01
        21: ([0, 1, 2], [2, 5, 3]),  // mean 1.100, target 1.05
        22: ([0, 1, 2], [2, 5, 3]),  // mean 1.100, target 1.09
        23: ([0, 1, 2, 3], [3, 4, 3, 1]),  // mean 1.182, target 1.14
        24: ([1, 2], [4, 1]),        // mean 1.200, target 1.20
        25: ([0, 1, 2], [1, 4, 3]),  // mean 1.250, target 1.26
        26: ([0, 1, 2, 3], [2, 4, 3, 1]),  // mean 1.300, target 1.31
        27: ([0, 1, 2, 3], [2, 4, 3, 1]),  // mean 1.300, target 1.35 — def L9
        28: ([1, 2], [3, 2]),        // mean 1.400, target 1.39
        29: ([1, 2], [3, 2]),        // mean 1.400, target 1.44
        30: ([1, 2], [1, 1]),        // mean 1.500, target 1.50
        31: ([1, 2], [1, 1]),        // mean 1.500, target 1.54
        32: ([1, 2], [2, 3]),        // mean 1.600, target 1.59
        33: ([1, 2], [1, 2]),        // mean 1.667, target 1.65
        34: ([1, 2], [3, 7]),        // mean 1.700, target 1.71
        35: ([1, 2], [3, 7]),        // mean 1.700, target 1.76
        36: ([1, 2], [1, 4]),        // mean 1.800, target 1.80 — def L12
        37: ([1, 2, 3], [3, 5, 2]),  // mean 1.900, target 1.84
        38: ([1, 2, 3], [3, 5, 2]),  // mean 1.900, target 1.89
        39: ([1, 2, 3], [3, 4, 3]),  // mean 2.000, target 1.95
        40: ([1, 2, 3], [3, 4, 3]),  // mean 2.000, target 2.01
        41: ([1, 2, 3], [2, 5, 3]),  // mean 2.100, target 2.06
        42: ([2, 3], [9, 1]),        // mean 2.100, target 2.10
        43: ([2, 3], [4, 1]),        // mean 2.200, target 2.14
        44: ([2, 3], [4, 1]),        // mean 2.200, target 2.19
        45: ([1, 2, 3], [1, 4, 3]),  // mean 2.250, target 2.25
        46: ([2, 3], [3, 1]),        // mean 2.250, target 2.28
        47: ([2, 3], [2, 1]),        // mean 2.333, target 2.33
        48: ([2, 3], [3, 2]),        // mean 2.400, target 2.40
        49: ([2, 3], [1, 1]),        // mean 2.500, target 2.48
        50: ([2, 3], [1, 1]),        // mean 2.500, target 2.52
        51: ([2, 3], [2, 3]),        // mean 2.600, target 2.55
        52: ([2, 3], [3, 7]),        // mean 2.700, target 2.70
    ]
}

//
//  ElfCritDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Default implementation of crit distribution strategy using tent/triangular distribution
///
/// **Algorithm**:
/// 1. Calculate minimum = power - instinct (can be negative)
/// 2. Calculate maximum = min(power, 100) (cap at 100%)
/// 3. Generate full range: minimum...maximum with tent-shaped weights
///
/// **Tent distribution**: Peak position is configurable via `GameMechanicsConstants.critPeakPosition`
/// - peakPosition = 0.0: Peak at maximum (favors higher chances)
/// - peakPosition = 1.0: Peak at minimum (favors lower chances)
/// - peakPosition = 0.5: Peak in the middle
///
/// **Negative values**: If selected value <= 0, crit automatically fails.
public final class ElfCritDistributionStrategy: CritDistributionStrategy {

    public init() {}

    public func distribution(power: Int16, instinct: Int16) -> CritDistribution {
        let powerInt = Int(power)
        let instinctInt = Int(instinct)

        // Calculate minimum crit chance (can be negative)
        let minimum = powerInt - instinctInt

        // Calculate maximum crit chance (cap at 100)
        let maximum = min(100, powerInt)

        // If minimum >= maximum, only one value exists
        guard minimum < maximum else {
            return CritDistribution(
                minimumChance: Int16(minimum),
                maximumChance: Int16(maximum),
                rangeValues: [Int16(minimum)],
                rangeWeights: [1]
            )
        }

        // Generate full range values: minimum...maximum (inclusive)
        let rangeValues = Array(minimum...maximum).map { Int16($0) }

        // Generate tent-shaped weights with configurable peak position
        let rangeSize = rangeValues.count
        let peakPosition = GameMechanicsConstants.critPeakPosition

        // Calculate peak index: 0.0 = last index (maximum), 1.0 = first index (minimum)
        let peakIndex = Int(round(peakPosition * Double(rangeSize - 1)))

        // Generate tent weights: weight = rangeSize - distance from peak
        let weights = (0..<rangeSize).map { index in
            let distance = abs(index - peakIndex)
            return max(1, rangeSize - distance)
        }

        return CritDistribution(
            minimumChance: Int16(minimum),
            maximumChance: Int16(maximum),
            rangeValues: rangeValues,
            rangeWeights: weights
        )
    }
}

// MARK: - Sendable Conformance
extension ElfCritDistributionStrategy: @unchecked Sendable {}

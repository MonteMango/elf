//
//  ElfDodgeDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import Foundation

/// Default implementation of dodge distribution strategy using tent/triangular distribution
///
/// **Algorithm**:
/// 1. Calculate minimum = agility - instinct (can be negative)
/// 2. Calculate maximum = min(agility, 100) (cap at 100%)
/// 3. Generate full range: minimum...maximum with tent-shaped weights
///
/// **Tent distribution**: Peak position is configurable via `GameMechanicsConstants.dodgePeakPosition`
/// - peakPosition = 0.0: Peak at maximum (favors higher chances)
/// - peakPosition = 1.0: Peak at minimum (favors lower chances)
/// - peakPosition = 0.5: Peak in the middle
///
/// **Negative values**: If selected value <= 0, dodge automatically fails.
public final class ElfDodgeDistributionStrategy: DodgeDistributionStrategy {

    public init() {}

    public func distribution(agility: Int16, instinct: Int16) -> DodgeDistribution {
        let agilityInt = Int(agility)
        let instinctInt = Int(instinct)

        // Calculate minimum dodge chance (can be negative)
        let minimum = agilityInt - instinctInt

        // Calculate maximum dodge chance (cap at 100)
        let maximum = min(100, agilityInt)

        // If minimum >= maximum, only one value exists
        guard minimum < maximum else {
            return DodgeDistribution(
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
        let peakPosition = GameMechanicsConstants.dodgePeakPosition

        // Calculate peak index: 0.0 = last index (maximum), 1.0 = first index (minimum)
        let peakIndex = Int(round(peakPosition * Double(rangeSize - 1)))

        // Generate tent weights: weight = rangeSize - distance from peak
        let weights = (0..<rangeSize).map { index in
            let distance = abs(index - peakIndex)
            return max(1, rangeSize - distance)
        }

        return DodgeDistribution(
            minimumChance: Int16(minimum),
            maximumChance: Int16(maximum),
            rangeValues: rangeValues,
            rangeWeights: weights
        )
    }
}

// MARK: - Sendable Conformance
extension ElfDodgeDistributionStrategy: @unchecked Sendable {}

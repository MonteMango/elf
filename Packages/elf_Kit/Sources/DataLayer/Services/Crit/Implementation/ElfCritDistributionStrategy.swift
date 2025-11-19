//
//  ElfCritDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Default implementation of crit distribution strategy using triangular distribution
///
/// **Algorithm**:
/// 1. Calculate minimum = power - instinct (can be negative)
/// 2. Calculate maximum = min(power, 100) (cap at 100%)
/// 3. If minimum >= maximum: no range, use only minimum
/// 4. Otherwise: range = (minimum + 1)...maximum with triangular weights
///
/// **Triangular weights**: For range of size N, weights are [N, N-1, N-2, ..., 2, 1]
/// This creates a linear decrease in probability from values closest to minimum.
public final class ElfCritDistributionStrategy: CritDistributionStrategy {

    public init() {}

    public func distribution(power: Int16, instinct: Int16) -> CritDistribution {
        let powerInt = Int(power)
        let instinctInt = Int(instinct)

        // Calculate minimum crit chance (can be negative)
        let rawMinimum = powerInt - instinctInt

        // Calculate maximum crit chance (cap at 100)
        let maximum = min(100, powerInt)

        // If minimum >= maximum, no range exists
        // This happens when power is very high (e.g., power=110, instinct=10 → min=100, max=100)
        guard rawMinimum < maximum else {
            return CritDistribution(
                minimumChance: Int16(rawMinimum),
                maximumChance: Int16(maximum),
                rangeValues: [],
                rangeWeights: []
            )
        }

        // Generate range values: (minimum + 1)...maximum
        let rangeStart = rawMinimum + 1
        let rangeEnd = maximum
        let rangeValues = Array(rangeStart...rangeEnd).map { Int16($0) }

        // Generate triangular weights: [n, n-1, n-2, ..., 2, 1]
        // where n = range size
        let rangeSize = rangeValues.count
        let weights = (0..<rangeSize).map { rangeSize - $0 }

        return CritDistribution(
            minimumChance: Int16(rawMinimum),
            maximumChance: Int16(maximum),
            rangeValues: rangeValues,
            rangeWeights: weights
        )
    }
}

// MARK: - Sendable Conformance
extension ElfCritDistributionStrategy: @unchecked Sendable {}

//
//  ElfDodgeDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import Foundation

/// Default implementation of dodge distribution strategy using triangular distribution
///
/// **Algorithm**:
/// 1. Calculate minimum = agility - instinct (can be negative)
/// 2. Calculate maximum = min(agility, 100) (cap at 100%)
/// 3. If minimum >= maximum: no range, use only minimum
/// 4. Otherwise: range = (minimum + 1)...maximum with triangular weights
///
/// **Triangular weights**: For range of size N, weights are [N, N-1, N-2, ..., 2, 1]
/// This creates a linear decrease in probability from values closest to minimum.
public final class ElfDodgeDistributionStrategy: DodgeDistributionStrategy {

    public init() {}

    public func distribution(agility: Int16, instinct: Int16) -> DodgeDistribution {
        let agilityInt = Int(agility)
        let instinctInt = Int(instinct)

        // Calculate minimum dodge chance (can be negative)
        let rawMinimum = agilityInt - instinctInt

        // Calculate maximum dodge chance (cap at 100)
        let maximum = min(100, agilityInt)

        // If minimum >= maximum, no range exists
        // This happens when agility is very high (e.g., agility=110, instinct=10 → min=100, max=100)
        guard rawMinimum < maximum else {
            return DodgeDistribution(
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

        return DodgeDistribution(
            minimumChance: Int16(rawMinimum),
            maximumChance: Int16(maximum),
            rangeValues: rangeValues,
            rangeWeights: weights
        )
    }
}

// MARK: - Sendable Conformance
extension ElfDodgeDistributionStrategy: @unchecked Sendable {}

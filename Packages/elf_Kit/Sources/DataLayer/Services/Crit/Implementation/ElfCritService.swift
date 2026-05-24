//
//  ElfCritService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Dependencies
import Foundation

/// Default implementation of crit calculation service.
///
/// Uses the peak+linear-tail distribution (configurable peak position +
/// peak weight):
/// 1. **Stage 1**: Select crit chance from the distribution
/// 2. **Stage 2**: Roll to check crit success (with auto-fail/success edge cases)
/// 3. **Stage 3**: Select damage multiplier from the fixed distribution
///    (defender stats no longer skew it)
public final class ElfCritService: CritService {

    private let distributionStrategy: any CritDistributionStrategy
    private let multiplierDistribution: CritMultiplierDistribution

    // MARK: - Initialization

    public init() {
        @Dependency(\.critDistributionStrategy) var distributionStrategy
        @Dependency(\.critMultiplierDistribution) var multiplierDistribution
        self.distributionStrategy = distributionStrategy
        self.multiplierDistribution = multiplierDistribution
    }

    // MARK: - CritService

    public func calculateCrit(power: Int16, instinct: Int16) -> CritCalculationResult {
        // Get distribution
        let distribution = distributionStrategy.distribution(
            power: power,
            instinct: instinct
        )

        // STAGE 1: Select crit chance from stage-1 distribution
        let selectedChance = selectCritChance(from: distribution)

        // STAGE 2: Check crit success with selected chance
        let (stage2Roll, success) = checkCritSuccess(chance: selectedChance)

        // STAGE 3: Select multiplier from the fixed distribution (only if crit succeeded)
        let (multiplierRoll, selectedMultiplier) = selectMultiplier(
            critSuccess: success,
            from: multiplierDistribution
        )

        return CritCalculationResult(
            distribution: distribution,
            selectedChance: selectedChance,
            stage2Roll: stage2Roll,
            success: success,
            multiplierDistribution: multiplierDistribution,
            multiplierRoll: multiplierRoll,
            selectedMultiplier: selectedMultiplier
        )
    }

    // MARK: - Private Methods

    /// Selects a crit chance from the distribution using weighted random selection
    ///
    /// Uses triangular distribution where minimum has highest weight.
    ///
    /// - Parameter distribution: The crit distribution
    /// - Returns: Selected crit chance
    private func selectCritChance(from distribution: CritDistribution) -> Int16 {
        // Use weighted random selection
        let totalWeight = distribution.rangeWeights.reduce(0, +)

        guard totalWeight > 0 else {
            return distribution.minimumChance
        }

        let weightedRoll = Int.random(in: 0..<totalWeight)

        var cumulativeWeight = 0
        for (index, weight) in distribution.rangeWeights.enumerated() {
            cumulativeWeight += weight
            if weightedRoll < cumulativeWeight {
                return distribution.rangeValues[index]
            }
        }

        // Fallback (should never reach)
        return distribution.rangeValues.last ?? distribution.minimumChance
    }

    /// Checks if crit succeeds with the selected chance
    ///
    /// **Logic**:
    /// - Chance <= 0: Auto-fail (no roll needed)
    /// - Chance >= 100: Auto-success (no roll needed)
    /// - Otherwise: Roll 1-100, succeed if roll <= chance
    ///
    /// - Parameter chance: The crit chance selected in stage 1
    /// - Returns: Tuple of (stage2Roll, success). Roll is nil for auto-fail/success cases.
    private func checkCritSuccess(chance: Int16) -> (roll: Int?, success: Bool) {
        let chanceInt = Int(chance)

        // Auto-fail for zero or negative chances
        if chanceInt <= 0 {
            return (nil, false)
        }

        // Auto-success for 100+ chances
        if chanceInt >= 100 {
            return (nil, true)
        }

        // Normal roll: 1-100, succeed if roll <= chance
        let roll = Int.random(in: 1...100)
        let success = roll <= chanceInt
        return (roll, success)
    }

    /// Selects damage multiplier from the given distribution if crit succeeded
    ///
    /// Uses weighted random selection from the adjusted distribution.
    /// If crit failed, returns (nil, 1.0)
    ///
    /// - Parameters:
    ///   - critSuccess: Whether the crit succeeded in stage 2
    ///   - distribution: The (possibly adjusted) multiplier distribution to select from
    /// - Returns: Tuple of (multiplierRoll, selectedMultiplier). Roll is nil if crit failed.
    private func selectMultiplier(critSuccess: Bool, from distribution: CritMultiplierDistribution) -> (roll: Int?, multiplier: Double) {
        guard critSuccess else {
            return (nil, 1.0)
        }

        // Use weighted random selection from adjusted distribution
        let totalWeight = distribution.totalWeight

        guard totalWeight > 0 else {
            return (nil, 1.0)
        }

        let roll = Int.random(in: 0..<totalWeight)

        var cumulativeWeight = 0
        for (index, weight) in distribution.weights.enumerated() {
            cumulativeWeight += weight
            if roll < cumulativeWeight {
                return (roll, distribution.values[index])
            }
        }

        // Fallback (should never reach)
        return (roll, distribution.values.last ?? 1.0)
    }
}

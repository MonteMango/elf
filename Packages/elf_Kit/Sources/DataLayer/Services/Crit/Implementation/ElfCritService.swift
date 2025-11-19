//
//  ElfCritService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Default implementation of crit calculation service
///
/// Implements the three-stage probability system:
/// 1. **Stage 1**: Select crit chance (40% for minimum, 60% triangular for range)
/// 2. **Stage 2**: Roll to check crit success (with auto-fail/success edge cases)
/// 3. **Stage 3**: Select damage multiplier if crit succeeded (1.25/1.5/2.0/3.0)
public final class ElfCritService: CritService {

    private let distributionStrategy: CritDistributionStrategy
    private let multiplierDistribution: CritMultiplierDistribution

    // MARK: - Initialization

    public init(distributionStrategy: CritDistributionStrategy) {
        self.distributionStrategy = distributionStrategy
        self.multiplierDistribution = CritMultiplierDistribution()
    }

    // MARK: - CritService

    public func calculateCrit(power: Int16, instinct: Int16) -> CritCalculationResult {
        // Get distribution
        let distribution = distributionStrategy.distribution(
            power: power,
            instinct: instinct
        )

        // STAGE 1: Select crit chance from distribution
        let stage1Roll = Int.random(in: 1...100)
        let selectedChance = selectCritChance(
            from: distribution,
            roll: stage1Roll
        )

        // STAGE 2: Check crit success with selected chance
        let (stage2Roll, success) = checkCritSuccess(chance: selectedChance)

        // STAGE 3: Select multiplier (only if crit succeeded)
        let (multiplierRoll, selectedMultiplier) = selectMultiplier(critSuccess: success)

        return CritCalculationResult(
            distribution: distribution,
            stage1Roll: stage1Roll,
            selectedChance: selectedChance,
            stage2Roll: stage2Roll,
            success: success,
            multiplierDistribution: multiplierDistribution,
            multiplierRoll: multiplierRoll,
            selectedMultiplier: selectedMultiplier
        )
    }

    // MARK: - Private Methods

    /// Selects a crit chance from the distribution using the stage 1 roll
    ///
    /// **Selection logic**:
    /// - Roll 1-40 (40%): Return minimum chance
    /// - Roll 41-100 (60%): Select from range using triangular distribution
    ///
    /// If no range exists (minimum >= maximum), always returns minimum.
    ///
    /// - Parameters:
    ///   - distribution: The crit distribution
    ///   - roll: Random roll 1-100
    /// - Returns: Selected crit chance
    private func selectCritChance(
        from distribution: CritDistribution,
        roll: Int
    ) -> Int16 {
        // 40% chance for minimum
        if roll <= 40 {
            return distribution.minimumChance
        }

        // No range → always minimum (shouldn't happen with roll > 40, but handle gracefully)
        guard distribution.hasRange else {
            return distribution.minimumChance
        }

        // 60% probability distributed triangularly over range values
        // Use weighted random selection
        let totalWeight = distribution.rangeWeights.reduce(0, +)
        let weightedRoll = Int.random(in: 0..<totalWeight)

        var cumulativeWeight = 0
        for (index, weight) in distribution.rangeWeights.enumerated() {
            cumulativeWeight += weight
            if weightedRoll < cumulativeWeight {
                return distribution.rangeValues[index]
            }
        }

        // Fallback (should never reach, but handle gracefully)
        return distribution.rangeValues.last ?? distribution.minimumChance
    }

    /// Checks if crit succeeds with the selected chance
    ///
    /// **Logic**:
    /// - Chance < 0: Auto-fail (no roll needed)
    /// - Chance >= 100: Auto-success (no roll needed)
    /// - Otherwise: Roll 1-100, succeed if roll <= chance
    ///
    /// - Parameter chance: The crit chance selected in stage 1
    /// - Returns: Tuple of (stage2Roll, success). Roll is nil for auto-fail/success cases.
    private func checkCritSuccess(chance: Int16) -> (roll: Int?, success: Bool) {
        let chanceInt = Int(chance)

        // Auto-fail for negative chances
        if chanceInt < 0 {
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

    /// Selects damage multiplier if crit succeeded
    ///
    /// **Multiplier distribution**:
    /// - 1.25x → 40% (weight 4)
    /// - 1.5x → 30% (weight 3)
    /// - 2.0x → 20% (weight 2)
    /// - 3.0x → 10% (weight 1)
    ///
    /// If crit failed, returns (nil, 1.0)
    ///
    /// - Parameter critSuccess: Whether the crit succeeded in stage 2
    /// - Returns: Tuple of (multiplierRoll, selectedMultiplier). Roll is nil if crit failed.
    private func selectMultiplier(critSuccess: Bool) -> (roll: Int?, multiplier: Double) {
        guard critSuccess else {
            return (nil, 1.0)
        }

        // Use weighted random selection
        let totalWeight = multiplierDistribution.totalWeight
        let roll = Int.random(in: 0..<totalWeight)

        var cumulativeWeight = 0
        for (index, weight) in multiplierDistribution.weights.enumerated() {
            cumulativeWeight += weight
            if roll < cumulativeWeight {
                return (roll, multiplierDistribution.values[index])
            }
        }

        // Fallback (should never reach)
        return (roll, multiplierDistribution.values.last ?? 1.0)
    }
}

// MARK: - Sendable Conformance
extension ElfCritService: @unchecked Sendable {}

//
//  ElfDodgeService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import Foundation

/// Default implementation of dodge calculation service
///
/// Implements the two-stage probability system:
/// 1. **Stage 1**: Select dodge chance (60% for minimum, 40% triangular for range)
/// 2. **Stage 2**: Roll to check dodge success (with auto-fail/success edge cases)
public final class ElfDodgeService: DodgeService {

    private let distributionStrategy: DodgeDistributionStrategy

    // MARK: - Initialization

    public init(distributionStrategy: DodgeDistributionStrategy) {
        self.distributionStrategy = distributionStrategy
    }

    // MARK: - DodgeService

    public func calculateDodge(agility: Int16, instinct: Int16) -> DodgeCalculationResult {
        // Get distribution
        let distribution = distributionStrategy.distribution(
            agility: agility,
            instinct: instinct
        )

        // STAGE 1: Select dodge chance from distribution
        let stage1Roll = Int.random(in: 1...100)
        let selectedChance = selectDodgeChance(
            from: distribution,
            roll: stage1Roll
        )

        // STAGE 2: Check dodge success with selected chance
        let (stage2Roll, success) = checkDodgeSuccess(chance: selectedChance)

        return DodgeCalculationResult(
            distribution: distribution,
            stage1Roll: stage1Roll,
            selectedChance: selectedChance,
            stage2Roll: stage2Roll,
            success: success
        )
    }

    // MARK: - Private Methods

    /// Selects a dodge chance from the distribution using the stage 1 roll
    ///
    /// **Selection logic**:
    /// - Roll 1-60 (60%): Return minimum chance
    /// - Roll 61-100 (40%): Select from range using triangular distribution
    ///
    /// If no range exists (minimum >= maximum), always returns minimum.
    ///
    /// - Parameters:
    ///   - distribution: The dodge distribution
    ///   - roll: Random roll 1-100
    /// - Returns: Selected dodge chance
    private func selectDodgeChance(
        from distribution: DodgeDistribution,
        roll: Int
    ) -> Int16 {
        // 60% chance for minimum
        if roll <= 60 {
            return distribution.minimumChance
        }

        // No range → always minimum (shouldn't happen with roll > 60, but handle gracefully)
        guard distribution.hasRange else {
            return distribution.minimumChance
        }

        // 40% probability distributed triangularly over range values
        // Use weighted random selection (same algorithm as ElfDamageService)
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

    /// Checks if dodge succeeds with the selected chance
    ///
    /// **Logic**:
    /// - Chance < 0: Auto-fail (no roll needed)
    /// - Chance >= 100: Auto-success (no roll needed)
    /// - Otherwise: Roll 1-100, succeed if roll <= chance
    ///
    /// - Parameter chance: The dodge chance selected in stage 1
    /// - Returns: Tuple of (stage2Roll, success). Roll is nil for auto-fail/success cases.
    private func checkDodgeSuccess(chance: Int16) -> (roll: Int?, success: Bool) {
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
}

// MARK: - Sendable Conformance
extension ElfDodgeService: @unchecked Sendable {}

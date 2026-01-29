//
//  CritMultiplierDistribution.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Probability distribution for critical hit damage multipliers
///
/// Defines weighted random selection of crit multipliers.
/// Default weights from `GameMechanicsConstants`:
/// - `0.75x` → 0% (weight 0)
/// - `1.00x` → 5% (weight 5)
/// - `1.25x` → 15% (weight 15)
/// - `1.50x` → 40% (weight 40)
/// - `2.00x` → 30% (weight 30)
/// - `3.00x` → 10% (weight 10)
///
/// This distribution can be adjusted based on defender's agility to redistribute
/// weights from high multipliers (1.5, 2.0, 3.0) to low multipliers (0.75, 1.00, 1.25).
public struct CritMultiplierDistribution: Equatable, Sendable {

    /// Available multiplier values
    public let values: [Double]

    /// Weights for each multiplier value
    public let weights: [Int]

    // MARK: - Initialization

    /// Creates the standard crit multiplier distribution from GameMechanicsConstants
    public init() {
        self.values = GameMechanicsConstants.critMultiplierValues
        self.weights = GameMechanicsConstants.critMultiplierWeights
    }

    /// Creates a custom crit multiplier distribution with specified values and weights
    ///
    /// - Parameters:
    ///   - values: Multiplier values (must match weights count)
    ///   - weights: Weights for each multiplier (higher = more likely)
    public init(values: [Double], weights: [Int]) {
        self.values = values
        self.weights = weights
    }

    // MARK: - Computed Properties

    /// Total weight sum
    public var totalWeight: Int {
        return weights.reduce(0, +)
    }

    // MARK: - Agility-based Adjustment

    /// Creates an adjusted distribution based on defender's agility advantage
    ///
    /// **Algorithm**:
    /// 1. Calculate `decreaser = ((agility * coefficient) - power) / agility`
    /// 2. If decreaser <= 0: Return original distribution (no adjustment)
    /// 3. If decreaser >= 1: Take 100% of weights from high multipliers
    /// 4. Take portion of weights from high multipliers (1.5, 2.0, 3.0)
    /// 5. Distribute taken weights equally among low multipliers (0.75, 1.00, 1.25)
    ///
    /// - Parameters:
    ///   - power: Attacker's total power attribute
    ///   - agility: Defender's total agility attribute
    /// - Returns: Adjusted distribution with redistributed weights and the decreaser value
    public func adjusted(attackerPower power: Int16, defenderAgility agility: Int16) -> (distribution: CritMultiplierDistribution, decreaser: Double) {
        let powerDouble = Double(power)
        let agilityDouble = Double(agility)

        // Avoid division by zero
        guard agilityDouble > 0 else {
            return (self, 0.0)
        }

        // Calculate decreaser: how much to shift weights from high to low multipliers
        let coefficient = GameMechanicsConstants.critMultiplierAgilityCoefficient
        let decreaser = ((agilityDouble * coefficient) - powerDouble) / agilityDouble

        // No adjustment if decreaser <= 0 (power is high enough)
        guard decreaser > 0 else {
            return (self, 0.0)
        }

        // Clamp decreaser to maximum 1.0
        let clampedDecreaser = min(1.0, decreaser)

        // Calculate weights to take from high multipliers (indices 3, 4, 5 = 1.5, 2.0, 3.0)
        // and redistribute to low multipliers (indices 0, 1, 2 = 0.75, 1.00, 1.25)
        var newWeights = weights

        // Take from high multipliers
        var totalTaken = 0
        for i in 3..<weights.count {
            let taken = Int(Double(weights[i]) * clampedDecreaser)
            newWeights[i] = weights[i] - taken
            totalTaken += taken
        }

        // Distribute equally among low multipliers (indices 0, 1, 2)
        let lowMultiplierCount = 3
        let perLowMultiplier = totalTaken / lowMultiplierCount
        let remainder = totalTaken % lowMultiplierCount

        for i in 0..<lowMultiplierCount {
            // Add extra 1 to first 'remainder' indices to distribute remainder
            let extra = i < remainder ? 1 : 0
            newWeights[i] = newWeights[i] + perLowMultiplier + extra
        }

        let adjustedDistribution = CritMultiplierDistribution(values: values, weights: newWeights)
        return (adjustedDistribution, clampedDecreaser)
    }
}

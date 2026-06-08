//
//  CritDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Strategy for generating critical hit chance probability distribution
///
/// Implementations should create a `CritDistribution` based on hero attributes,
/// determining:
/// - Minimum crit chance (`power − round(instinct × multiplier)`)
/// - Maximum crit chance (power, cap at 100)
/// - Range values and their peak+linear-tail weights
public protocol CritDistributionStrategy: Sendable {

    /// Creates a crit distribution based on attacker's power and defender's instinct
    ///
    /// **Formula**:
    /// - Minimum = `power − round(instinct × multiplier)` (can be negative)
    /// - Maximum = `min(100, power)`
    /// - Range = minimum...maximum (inclusive)
    ///
    /// **Peak + linear-tail distribution** (shape lives in
    /// `PeakLinearTailDistribution`): one bucket gets the configured share
    /// of probability mass (`GameMechanicsConstants.critPeakWeight`), the
    /// remaining mass spreads with a linear falloff from the peak toward
    /// both edges. Peak location is set by `critPeakPosition`.
    ///
    /// - Parameters:
    ///   - power: Attacker's total power attribute
    ///   - instinct: Defender's total instinct attribute
    ///   - attackerLevel: Attacker's character level. Scales the intuition
    ///     suppression multiplier — `base + perLevel × attackerLevel`.
    /// - Returns: Distribution with minimum, maximum, range values, and peak+linear-tail weights
    func distribution(power: Int16, instinct: Int16, attackerLevel: Int) -> CritDistribution
}

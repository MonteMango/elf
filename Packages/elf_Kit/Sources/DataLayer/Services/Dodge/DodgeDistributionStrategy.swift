//
//  DodgeDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import Foundation

/// Strategy for generating dodge chance probability distribution
///
/// Implementations should create a `DodgeDistribution` based on hero attributes,
/// determining:
/// - Minimum dodge chance (`agility − round(instinct × multiplier)`)
/// - Maximum dodge chance (agility, cap at 100)
/// - Range values and their peak+linear-tail weights
public protocol DodgeDistributionStrategy: Sendable {

    /// Creates a dodge distribution based on defender's agility and attacker's instinct
    ///
    /// **Formula**:
    /// - Minimum = `agility − round(instinct × multiplier)` (can be negative)
    /// - Maximum = `min(100, agility)`
    /// - Range = minimum...maximum (inclusive)
    ///
    /// **Peak + linear-tail distribution** (shape lives in
    /// `PeakLinearTailDistribution`): one bucket gets the configured share
    /// of probability mass (`GameMechanicsConstants.dodgePeakWeight`), the
    /// remaining mass spreads with a linear falloff from the peak toward
    /// both edges. Peak location is set by `dodgePeakPosition`.
    ///
    /// - Parameters:
    ///   - agility: Defender's total agility attribute
    ///   - instinct: Attacker's total instinct attribute
    ///   - attackerLevel: Attacker's character level. The intuition
    ///     suppression multiplier scales linearly:
    ///     `base + perLevel × attackerLevel`. Higher-level intuition
    ///     suppresses dodge harder.
    /// - Returns: Distribution with minimum, maximum, range values, and peak+linear-tail weights
    func distribution(agility: Int16, instinct: Int16, attackerLevel: Int) -> DodgeDistribution
}

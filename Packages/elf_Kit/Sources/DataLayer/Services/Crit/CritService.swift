//
//  CritService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Dependencies

/// Service for calculating critical hit success and multiplier.
///
/// **Algorithm**:
///
/// **Stage 1**: Select crit chance from the peak+linear-tail distribution
/// - Range: minimum...maximum where minimum = power - instinct, maximum = min(power, 100)
/// - Weights: Configurable via `GameMechanicsConstants.critPeakPosition` /
///   `critPeakWeight`
///
/// **Stage 2**: Check crit success with selected chance
/// - If chance <= 0: Auto-fail
/// - If chance >= 100: Auto-success
/// - Otherwise: Roll 1-100, succeed if roll <= chance
///
/// **Stage 3**: Select damage multiplier from the fixed multiplier
/// distribution (only if crit succeeded). Defender stats no longer skew
/// the multiplier — see `CritMultiplierDistribution`.
public protocol CritService: Sendable {

    /// Calculates critical hit result.
    ///
    /// - Parameters:
    ///   - power: Attacker's total power attribute
    ///   - instinct: Defender's total instinct attribute
    ///   - attackerLevel: Attacker's character level (scales suppression).
    ///   - generator: Per-battle random source, threaded from the battle boundary.
    /// - Returns: Complete calculation result including distribution, rolls, success, and multiplier
    func calculateCrit(power: Int16, instinct: Int16, attackerLevel: Int, using generator: WithRandomNumberGenerator) -> CritCalculationResult
}

public extension CritService {
    /// Convenience: resolves `\.withRandomNumberGenerator` once and delegates.
    func calculateCrit(power: Int16, instinct: Int16, attackerLevel: Int) -> CritCalculationResult {
        @Dependency(\.withRandomNumberGenerator) var generator
        return calculateCrit(power: power, instinct: instinct, attackerLevel: attackerLevel, using: generator)
    }
}

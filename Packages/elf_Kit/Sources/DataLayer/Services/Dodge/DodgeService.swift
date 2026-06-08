//
//  DodgeService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import Dependencies

/// Service for calculating dodge success using the peak+linear-tail distribution
///
/// **Algorithm**:
///
/// **Stage 1**: Select dodge chance from the peak+linear-tail distribution
/// - Range: minimum...maximum where
///   `minimum = agility − round(instinct × multiplier)`,
///   `maximum = min(100, agility)`
/// - Weights: configurable via `GameMechanicsConstants.dodgePeakPosition` /
///   `dodgePeakWeight`
///
/// **Stage 2**: Check dodge success with selected chance
/// - If chance <= 0: Auto-fail
/// - If chance >= 100: Auto-success
/// - Otherwise: Roll 1-100, succeed if roll <= chance
public protocol DodgeService: Sendable {

    /// Calculates dodge attempt result.
    ///
    /// - Parameters:
    ///   - agility: Defender's total agility attribute
    ///   - instinct: Attacker's total instinct attribute
    ///   - attackerLevel: Attacker's character level (scales the intuition
    ///     suppression multiplier — see `DodgeDistributionStrategy`).
    ///   - generator: Per-battle random source, threaded from the battle boundary.
    /// - Returns: Complete calculation result including distribution, rolls, and final success
    func calculateDodge(agility: Int16, instinct: Int16, attackerLevel: Int, using generator: WithRandomNumberGenerator) -> DodgeCalculationResult
}

public extension DodgeService {
    /// Convenience: resolves `\.withRandomNumberGenerator` once and delegates.
    func calculateDodge(agility: Int16, instinct: Int16, attackerLevel: Int) -> DodgeCalculationResult {
        @Dependency(\.withRandomNumberGenerator) var generator
        return calculateDodge(agility: agility, instinct: instinct, attackerLevel: attackerLevel, using: generator)
    }
}

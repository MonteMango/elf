//
//  CritService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Service for calculating critical hit success and multiplier using triangular distribution
///
/// **Algorithm**:
///
/// **Stage 1**: Select crit chance from triangular distribution
/// - Range: minimum...maximum where minimum = power - instinct, maximum = min(power, 100)
/// - Weights: Configurable via `GameMechanicsConstants.critPeakPosition`
///
/// **Stage 2**: Check crit success with selected chance
/// - If chance <= 0: Auto-fail
/// - If chance >= 100: Auto-success
/// - Otherwise: Roll 1-100, succeed if roll <= chance
///
/// **Stage 3**: Select damage multiplier (only if crit succeeded)
/// - Multiplier distribution is adjusted based on defender's agility
/// - High agility shifts weights from high multipliers (1.5, 2.0, 3.0) to low (0.75, 1.00, 1.25)
public protocol CritService: Sendable {

    /// Calculates critical hit result using triangular distribution with agility-based multiplier adjustment
    ///
    /// - Parameters:
    ///   - power: Attacker's total power attribute
    ///   - instinct: Defender's total instinct attribute
    ///   - defenderAgility: Defender's total agility attribute (used for multiplier weight adjustment)
    /// - Returns: Complete calculation result including distribution, rolls, success, and multiplier
    func calculateCrit(power: Int16, instinct: Int16, defenderAgility: Int16) async -> CritCalculationResult
}

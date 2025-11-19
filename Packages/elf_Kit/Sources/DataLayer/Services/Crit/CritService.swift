//
//  CritService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Service for calculating critical hit success and multiplier using three-stage probability system
///
/// **Three-Stage Algorithm**:
///
/// **Stage 1**: Select crit chance from distribution
/// - 40% probability: Use minimum chance (power - instinct)
/// - 60% probability: Select from range using triangular distribution
///
/// **Stage 2**: Check crit success with selected chance
/// - If chance < 0: Auto-fail
/// - If chance >= 100: Auto-success
/// - Otherwise: Roll 1-100, succeed if roll <= chance
///
/// **Stage 3**: Select damage multiplier (only if crit succeeded)
/// - 1.25x → 40% (weight 4)
/// - 1.5x → 30% (weight 3)
/// - 2.0x → 20% (weight 2)
/// - 3.0x → 10% (weight 1)
public protocol CritService: Sendable {

    /// Calculates critical hit result using three-stage probability system
    ///
    /// - Parameters:
    ///   - power: Attacker's total power attribute
    ///   - instinct: Defender's total instinct attribute
    /// - Returns: Complete calculation result including distribution, rolls, success, and multiplier
    func calculateCrit(power: Int16, instinct: Int16) -> CritCalculationResult
}

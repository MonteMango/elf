//
//  DodgeService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import Foundation

/// Service for calculating dodge success using triangular distribution
///
/// **Algorithm**:
///
/// **Stage 1**: Select dodge chance from triangular distribution
/// - Range: minimum...maximum where minimum = agility - instinct, maximum = min(agility, 100)
/// - Weights: [n, n-1, ..., 1] - minimum has highest probability, maximum has lowest
///
/// **Stage 2**: Check dodge success with selected chance
/// - If chance <= 0: Auto-fail
/// - If chance >= 100: Auto-success
/// - Otherwise: Roll 1-100, succeed if roll <= chance
public protocol DodgeService: Sendable {

    /// Calculates dodge attempt result using triangular distribution
    ///
    /// - Parameters:
    ///   - agility: Defender's total agility attribute
    ///   - instinct: Attacker's total instinct attribute
    /// - Returns: Complete calculation result including distribution, rolls, and final success
    func calculateDodge(agility: Int16, instinct: Int16) async -> DodgeCalculationResult
}

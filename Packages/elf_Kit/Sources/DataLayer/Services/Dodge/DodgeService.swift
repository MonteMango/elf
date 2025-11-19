//
//  DodgeService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import Foundation

/// Service for calculating dodge success using two-stage probability system
///
/// **Two-Stage Algorithm**:
///
/// **Stage 1**: Select dodge chance from distribution
/// - 60% probability: Use minimum chance (agility - instinct)
/// - 40% probability: Select from range using triangular distribution
///
/// **Stage 2**: Check dodge success with selected chance
/// - If chance < 0: Auto-fail
/// - If chance >= 100: Auto-success
/// - Otherwise: Roll 1-100, succeed if roll <= chance
public protocol DodgeService: Sendable {

    /// Calculates dodge attempt result using two-stage probability system
    ///
    /// - Parameters:
    ///   - agility: Defender's total agility attribute
    ///   - instinct: Attacker's total instinct attribute
    /// - Returns: Complete calculation result including distribution, rolls, and final success
    func calculateDodge(agility: Int16, instinct: Int16) -> DodgeCalculationResult
}

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
/// - Minimum dodge chance (agility - instinct)
/// - Maximum dodge chance (agility, cap at 100)
/// - Range values and their triangular weights
public protocol DodgeDistributionStrategy: Sendable {

    /// Creates a dodge distribution based on defender's agility and attacker's instinct
    ///
    /// **Formula**:
    /// - Minimum = agility - instinct (can be negative)
    /// - Maximum = agility (cap at 100)
    /// - Range = (minimum + 1)...maximum
    ///
    /// **Probability split**:
    /// - Minimum: 60% probability
    /// - Range: 40% total, distributed triangularly
    ///
    /// - Parameters:
    ///   - agility: Defender's total agility attribute
    ///   - instinct: Attacker's total instinct attribute
    /// - Returns: Distribution with minimum, maximum, range values, and triangular weights
    func distribution(agility: Int16, instinct: Int16) -> DodgeDistribution
}

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
/// - Minimum crit chance (power - instinct)
/// - Maximum crit chance (power, cap at 100)
/// - Range values and their triangular weights
public protocol CritDistributionStrategy: Sendable {

    /// Creates a crit distribution based on attacker's power and defender's instinct
    ///
    /// **Formula**:
    /// - Minimum = power - instinct (can be negative)
    /// - Maximum = power (cap at 100)
    /// - Range = minimum...maximum (inclusive)
    ///
    /// **Triangular distribution**:
    /// - Minimum has highest weight
    /// - Maximum has lowest weight
    /// - Weights: [n, n-1, n-2, ..., 2, 1]
    ///
    /// - Parameters:
    ///   - power: Attacker's total power attribute
    ///   - instinct: Defender's total instinct attribute
    /// - Returns: Distribution with minimum, maximum, range values, and triangular weights
    func distribution(power: Int16, instinct: Int16) async -> CritDistribution
}

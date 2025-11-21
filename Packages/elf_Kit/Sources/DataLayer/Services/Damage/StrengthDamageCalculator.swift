//
//  StrengthDamageCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Calculates damage based on strength attribute
public protocol StrengthDamageCalculator: Sendable {

    /// Get minimum and maximum strength damage for a strength attribute value
    ///
    /// - Parameter strengthAttribute: The strength attribute value
    /// - Returns: Tuple of (minDmg, maxDmg) or nil if invalid
    func getMinMaxStrengthDamage(_ strengthAttribute: Int16) async -> (minDmg: Int16, maxDmg: Int16)?

    /// Get strength damage distribution with values and weights for debug logging
    ///
    /// - Parameter strengthAttribute: The strength attribute value
    /// - Returns: Tuple of (distribution values, weights)
    func getStrengthDamageDistribution(_ strengthAttribute: Int16) async -> (distribution: [Int16], weights: [Int])

    /// Get random strength damage value based on weighted distribution
    ///
    /// - Parameter strengthAttribute: The strength attribute value
    /// - Returns: Random damage value
    func getRandomStrengthDamage(_ strengthAttribute: Int16) async -> Int16
}

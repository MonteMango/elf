//
//  StrengthDamageCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Calculates damage based on strength attribute
public protocol StrengthDamageCalculator: Sendable {

    /// Get random strength damage value based on weighted distribution
    ///
    /// - Parameter strengthAttribute: The strength attribute value
    /// - Returns: Random damage value
    func getRandomStrengthDamage(_ strengthAttribute: Int16) async -> Int16
}

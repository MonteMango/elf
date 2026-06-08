//
//  StrengthDamageCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Dependencies

/// Calculates damage based on strength attribute
public protocol StrengthDamageCalculator: Sendable {

    /// Get random strength damage value based on weighted distribution.
    /// The generator is threaded in so the whole battle shares one source.
    ///
    /// - Parameters:
    ///   - strengthAttribute: The strength attribute value
    ///   - generator: Per-battle random source.
    /// - Returns: Random damage value
    func getRandomStrengthDamage(_ strengthAttribute: Int16, using generator: WithRandomNumberGenerator) -> Int16
}

public extension StrengthDamageCalculator {
    /// Convenience: resolves `\.withRandomNumberGenerator` once and delegates.
    func getRandomStrengthDamage(_ strengthAttribute: Int16) -> Int16 {
        @Dependency(\.withRandomNumberGenerator) var generator
        return getRandomStrengthDamage(strengthAttribute, using: generator)
    }
}

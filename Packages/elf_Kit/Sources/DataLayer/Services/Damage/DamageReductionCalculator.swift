//
//  DamageReductionCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

/// Rolls damage reduction for any defensive stat (Intuition, Endurance)
/// using the shared sqrt-curve distribution. Mirror of
/// `StrengthDamageCalculator` on the offensive side, but parameterised so
/// multiple defensive stats can contribute independently with different
/// effectiveness multipliers.
public protocol DamageReductionCalculator: Sendable {

    /// - Parameters:
    ///   - stat: The defender's attribute value (Intuition, Endurance, …).
    ///   - coefficient: `mean_reduction = sqrt(stat) × coefficient`.
    ///     E.g. `0.12` for Intuition (20 % of strength damage), `0.18` for
    ///     Endurance (30 %).
    ///   - generator: Per-battle random source.
    /// - Returns: Random reduction value rolled from the distribution.
    func getRandomDamageReduction(stat: Int16, coefficient: Double, using generator: WithRandomNumberGenerator) -> Int16
}

public extension DamageReductionCalculator {
    /// Convenience: resolves `\.withRandomNumberGenerator` once and delegates.
    func getRandomDamageReduction(stat: Int16, coefficient: Double) -> Int16 {
        @Dependency(\.withRandomNumberGenerator) var generator
        return getRandomDamageReduction(stat: stat, coefficient: coefficient, using: generator)
    }
}

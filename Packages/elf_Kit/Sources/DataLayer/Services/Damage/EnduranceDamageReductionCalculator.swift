//
//  EnduranceDamageReductionCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Calculates damage reduction based on endurance attribute. Mirror of
/// `StrengthDamageCalculator` — instead of an attacker bonus added to damage,
/// produces a defender deduction subtracted from it.
public protocol EnduranceDamageReductionCalculator: Sendable {

    /// Get random endurance damage reduction value based on weighted distribution.
    ///
    /// - Parameter enduranceAttribute: The endurance attribute value of the defender
    /// - Returns: Random damage reduction value
    func getRandomEnduranceDamageReduction(_ enduranceAttribute: Int16) -> Int16
}

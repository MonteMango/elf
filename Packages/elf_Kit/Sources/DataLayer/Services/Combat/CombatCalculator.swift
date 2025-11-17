//
//  CombatCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public protocol CombatCalculator: Sendable {
    /// Calculate combat results for all body parts based on attack and defense selections
    /// - Parameters:
    ///   - attackingPoints: Body parts being attacked
    ///   - defendingPoints: Body parts being defended
    ///   - attacker: Hero performing the attack
    ///   - defender: Hero being attacked
    /// - Returns: Dictionary mapping body parts to their combat status
    func calculatePointStatus(
        attackingPoints: Set<BodyPart>,
        defendingPoints: Set<BodyPart>,
        attacker: ElfHero,
        defender: ElfHero
    ) async -> [BodyPart: PointStatus]
}

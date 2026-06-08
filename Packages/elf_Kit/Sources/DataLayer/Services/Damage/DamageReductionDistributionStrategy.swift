//
//  DamageReductionDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

/// Damage-reduction distribution. Same sqrt-curve shape as strength damage,
/// scaled by a per-call `coefficient`. The caller decides which defensive
/// stat to feed (Intuition, Endurance) and at what effectiveness multiplier
/// (e.g. `0.12` = 20 % of strength, `0.18` = 30 %).
public protocol DamageReductionDistributionStrategy: Sendable {
    func distribution(for stat: Int16, coefficient: Double) -> DamageDistribution
}

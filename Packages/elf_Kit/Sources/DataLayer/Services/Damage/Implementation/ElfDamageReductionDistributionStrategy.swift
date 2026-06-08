//
//  ElfDamageReductionDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

/// `mean_reduction = sqrt(stat) × coefficient`. Caller picks `coefficient`
/// to express "X % of equivalent strength damage" (strength itself uses
/// `0.6` for damage; reduction multipliers are e.g. `0.12` for Intuition →
/// 20 %, `0.18` for Endurance → 30 %).
///
/// Shape and weight scaling live in `SqrtCurveDistribution`.
public struct ElfDamageReductionDistributionStrategy: DamageReductionDistributionStrategy {

    public init() {}

    public func distribution(for stat: Int16, coefficient: Double) -> DamageDistribution {
        SqrtCurveDistribution.distribution(stat: stat, coefficient: coefficient)
    }
}

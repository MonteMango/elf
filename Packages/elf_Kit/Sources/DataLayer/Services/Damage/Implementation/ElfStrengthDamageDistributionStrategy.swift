//
//  ElfStrengthDamageDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 11.07.25.
//

/// Damage distribution where mean grows as `sqrt(strength) × 0.6` — true
/// diminishing returns. Each additional Strength point matters less than the
/// last, mitigating runaway dominance from stat-stacking (a class with
/// `2 × level` Strength deals only ~41 % more damage than `1 × level`, not
/// 100 % as the prior linear table did).
///
/// **Calibration:** `k = 0.6` matches the prior hand-tuned table at the
/// typical mid-game value (str 12 → mean ≈ 2.0). Higher str values grow
/// slower than before:
///   - str 12: mean 2.1
///   - str 24: mean 2.9
///   - str 48: mean 4.2
///   - str 100: mean 6.0
///
/// Shape and weight scaling live in `SqrtCurveDistribution`.
public struct ElfStrengthDamageDistributionStrategy: StrengthDamageDistributionStrategy {

    private static let coefficient: Double = 0.6

    public init() {}

    public func distribution(for strength: Int16) -> DamageDistribution {
        SqrtCurveDistribution.distribution(stat: strength, coefficient: Self.coefficient)
    }
}

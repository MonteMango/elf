//
//  SqrtCurveDistribution.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Shared sqrt-curve distribution shaper used by both the strength damage
/// strategy and the damage-reduction strategy. Mean grows as
/// `sqrt(stat) × coefficient` with diminishing returns; distribution is
/// always two adjacent integers `[floor(mean), ceil(mean)]` with weights
/// summing to `distributionWeightTotal` (10) — fractional mean accuracy ±0.05.
public enum SqrtCurveDistribution {

    /// Weight scale used by the two-value `[floor, ceil]` distribution.
    /// Captures the fractional part of the mean within `1 / total = 0.1`.
    public static let weightTotal: Int = 10

    /// Builds a `DamageDistribution` whose rolled mean ≈ `sqrt(stat) × coefficient`.
    ///
    /// - Parameters:
    ///   - stat: Source attribute value (str, int, end…). Non-positive values yield `[0]`.
    ///   - coefficient: `k` in `mean = sqrt(stat) × k`. Non-positive yields `[0]`.
    public static func distribution(stat: Int16, coefficient: Double) -> DamageDistribution {
        guard stat > 0, coefficient > 0 else {
            return DamageDistribution(values: [0], weights: [1])
        }
        let mean = sqrt(Double(stat)) * coefficient
        let floorVal = Int16(mean.rounded(.down))
        let ceilVal = floorVal + 1
        let fraction = mean - Double(floorVal)
        let ceilWeight = Int((fraction * Double(weightTotal)).rounded())
        let floorWeight = weightTotal - ceilWeight

        if ceilWeight == 0 {
            return DamageDistribution(values: [floorVal], weights: [1])
        }
        if floorWeight == 0 {
            return DamageDistribution(values: [ceilVal], weights: [1])
        }
        return DamageDistribution(values: [floorVal, ceilVal], weights: [floorWeight, ceilWeight])
    }
}

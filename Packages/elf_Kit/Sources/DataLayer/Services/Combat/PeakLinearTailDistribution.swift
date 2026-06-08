//
//  PeakLinearTailDistribution.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Shared "peak + linear-tail" distribution shaper used by both the dodge and
/// crit chance strategies.
///
/// Builds an integer chance range `[min, max]` where:
/// - `min = primaryStat − round(opposingStat × multiplier)` (clamped 0+ at the
///   call site if needed)
/// - `max = min(100, primaryStat)`
///
/// The level-scaled `multiplier` is `base + perLevel × attackerLevel`. The
/// rolled distribution has all probability mass on the peak (per
/// `peakWeightShare`) plus a linear-falloff tail.
public enum PeakLinearTailDistribution {

    /// The level-scaling multiplier formula used by both dodge and crit.
    public static func multiplier(base: Double, perLevel: Double, attackerLevel: Int) -> Double {
        base + perLevel * Double(attackerLevel)
    }

    /// Result of a chance-range computation, ready to be wrapped into the
    /// concrete `DodgeDistribution` or `CritDistribution`.
    public struct Range {
        public let minimum: Int
        public let maximum: Int
        public let values: [Int16]
        public let weights: [Int]
    }

    /// Builds the peak+linear-tail range. Caller wraps the result into the
    /// appropriate concrete distribution type.
    ///
    /// - Parameters:
    ///   - primaryStat: attacker's `power` for crit, defender's `agility` for dodge.
    ///   - opposingStat: opposing intuition that suppresses the chance.
    ///   - multiplier: level-scaled suppression factor; pre-computed by caller via `multiplier(base:perLevel:attackerLevel:)`.
    ///   - peakPosition: `0.0` = peak at minimum, `1.0` = peak at maximum.
    ///   - peakWeightShare: fraction of total probability the peak claims; clamped to `[0, 0.999]`.
    public static func range(
        primaryStat: Int16,
        opposingStat: Int16,
        multiplier: Double,
        peakPosition: Double,
        peakWeightShare: Double
    ) -> Range {
        let primary = Int(primaryStat)
        let opposing = Int(opposingStat)
        let suppressed = Int((Double(opposing) * multiplier).rounded())
        let minimum = primary - suppressed
        let maximum = min(100, primary)

        guard minimum < maximum else {
            return Range(
                minimum: minimum,
                maximum: maximum,
                values: [Int16(minimum)],
                weights: [1]
            )
        }

        let values = Array(minimum...maximum).map { Int16($0) }
        let rangeSize = values.count
        let peakIndex = Int(round(peakPosition * Double(rangeSize - 1)))
        let weights = makeWeights(
            rangeSize: rangeSize,
            peakIndex: peakIndex,
            peakWeightShare: peakWeightShare
        )

        return Range(minimum: minimum, maximum: maximum, values: values, weights: weights)
    }

    /// Builds integer weights where `weights[peakIndex] / sum(weights) ≈
    /// peakWeightShare` and the rest taper linearly from peak toward both
    /// edges (floor 1). Tail weights are integer (computed from
    /// `rangeSize − distance`); the peak weight is derived to satisfy the
    /// requested share, with a safety clamp for `peakWeightShare → 1.0`.
    private static func makeWeights(rangeSize: Int, peakIndex: Int, peakWeightShare: Double) -> [Int] {
        var weights = (0..<rangeSize).map { index -> Int in
            let distance = abs(index - peakIndex)
            return distance == 0 ? 0 : max(1, rangeSize - distance)
        }
        let nonPeakSum = weights.reduce(0, +)
        let clampedShare = max(0.0, min(0.999, peakWeightShare))

        // Solve peak / (peak + nonPeakSum) = share → peak = nonPeakSum * share / (1 - share).
        // nonPeakSum can be 0 only when rangeSize == 1, which we already returned above.
        let peakWeight = Int(round(Double(nonPeakSum) * clampedShare / (1.0 - clampedShare)))
        weights[peakIndex] = peakWeight

        return weights
    }
}

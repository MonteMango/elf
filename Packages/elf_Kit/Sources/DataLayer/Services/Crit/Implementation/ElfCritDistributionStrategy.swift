//
//  ElfCritDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Default implementation of crit distribution strategy using a peak +
/// linear-tail distribution.
///
/// **Algorithm**:
/// 1. Calculate `minimum = power - instinct` (can be negative).
/// 2. Calculate `maximum = min(power, 100)` (cap at 100%).
/// 3. Generate full range `minimum...maximum`.
/// 4. Pick the peak index from `GameMechanicsConstants.critPeakPosition`.
/// 5. Assign weights so the peak claims exactly `critPeakWeight` of the
///    total probability mass; the remaining `1 − critPeakWeight` is split
///    among non-peak values with a linear falloff from peak to edges (floor 1).
///
/// **Peak position** (`critPeakPosition`):
/// - `0.0`: peak at **minimum** (favors lower chances)
/// - `0.5`: peak in the middle
/// - `1.0`: peak at **maximum** (favors higher chances)
///
/// **Peak weight** (`critPeakWeight`): exact share of total probability the
/// peak takes — independent of range size. `0.6` → peak rolled 60%, the
/// other 40% spreads linearly. `0.0` → peak takes nothing, the tail keeps
/// 100%. Values `≥ 0.999` are clamped to keep the tail non-degenerate.
///
/// **Negative values**: If the rolled chance is `≤ 0`, crit auto-fails.
public final class ElfCritDistributionStrategy: CritDistributionStrategy {

    public init() {}

    public func distribution(power: Int16, instinct: Int16) -> CritDistribution {
        let powerInt = Int(power)
        let instinctInt = Int(instinct)

        // Calculate minimum crit chance (can be negative)
        let minimum = powerInt - instinctInt

        // Calculate maximum crit chance (cap at 100)
        let maximum = min(100, powerInt)

        // If minimum >= maximum, only one value exists
        guard minimum < maximum else {
            return CritDistribution(
                minimumChance: Int16(minimum),
                maximumChance: Int16(maximum),
                rangeValues: [Int16(minimum)],
                rangeWeights: [1]
            )
        }

        let rangeValues = Array(minimum...maximum).map { Int16($0) }
        let rangeSize = rangeValues.count
        let peakPosition = GameMechanicsConstants.critPeakPosition
        let peakWeightShare = GameMechanicsConstants.critPeakWeight

        // Peak index: 0.0 → first index (= minimum), 1.0 → last index (= maximum)
        let peakIndex = Int(round(peakPosition * Double(rangeSize - 1)))

        let weights = makeWeights(
            rangeSize: rangeSize,
            peakIndex: peakIndex,
            peakWeightShare: peakWeightShare
        )

        return CritDistribution(
            minimumChance: Int16(minimum),
            maximumChance: Int16(maximum),
            rangeValues: rangeValues,
            rangeWeights: weights
        )
    }

    /// Builds integer weights where `weights[peakIndex] / sum(weights) ≈
    /// peakWeightShare` and the rest taper linearly from peak toward both
    /// edges (floor 1). Tail weights are integer (computed from
    /// `rangeSize − distance`); the peak weight is derived to satisfy the
    /// requested share, with a safety clamp for `peakWeightShare → 1.0`.
    private func makeWeights(rangeSize: Int, peakIndex: Int, peakWeightShare: Double) -> [Int] {
        // Linear tail weights (excluding the peak itself).
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

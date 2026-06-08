//
//  ElfCritDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

/// Crit chance distribution. Mirrors `ElfDodgeDistributionStrategy` —
/// both share the underlying shape via `PeakLinearTailDistribution`.
///
/// Range: `[power − round(instinct × critMultiplier), min(100, power)]`.
/// The multiplier scales with attacker level: `base + perLevel × attackerLevel`.
///
/// Peak position + weight come from `GameMechanicsConstants.critPeak*`.
/// Negative chance → auto-fail at roll time.
public struct ElfCritDistributionStrategy: CritDistributionStrategy {

    public init() {}

    public func distribution(power: Int16, instinct: Int16, attackerLevel: Int) -> CritDistribution {
        let multiplier = PeakLinearTailDistribution.multiplier(
            base: GameMechanicsConstants.critIntuitionSuppressionBaseMultiplier,
            perLevel: GameMechanicsConstants.critIntuitionSuppressionPerLevelDelta,
            attackerLevel: attackerLevel
        )
        let range = PeakLinearTailDistribution.range(
            primaryStat: power,
            opposingStat: instinct,
            multiplier: multiplier,
            peakPosition: GameMechanicsConstants.critPeakPosition,
            peakWeightShare: GameMechanicsConstants.critPeakWeight
        )
        return CritDistribution(
            minimumChance: Int16(range.minimum),
            maximumChance: Int16(range.maximum),
            rangeValues: range.values,
            rangeWeights: range.weights
        )
    }
}

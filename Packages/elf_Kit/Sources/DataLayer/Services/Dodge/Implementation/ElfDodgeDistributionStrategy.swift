//
//  ElfDodgeDistributionStrategy.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

/// Dodge chance distribution. Mirrors `ElfCritDistributionStrategy` —
/// both share the underlying shape via `PeakLinearTailDistribution`.
///
/// Range: `[agility − round(instinct × dodgeMultiplier), min(100, agility)]`.
/// The multiplier scales with attacker level: `base + perLevel × attackerLevel`.
///
/// Peak position + weight come from `GameMechanicsConstants.dodgePeak*`.
/// Negative chance → auto-fail at roll time.
public struct ElfDodgeDistributionStrategy: DodgeDistributionStrategy {

    public init() {}

    public func distribution(agility: Int16, instinct: Int16, attackerLevel: Int) -> DodgeDistribution {
        let multiplier = PeakLinearTailDistribution.multiplier(
            base: GameMechanicsConstants.dodgeIntuitionSuppressionBaseMultiplier,
            perLevel: GameMechanicsConstants.dodgeIntuitionSuppressionPerLevelDelta,
            attackerLevel: attackerLevel
        )
        let range = PeakLinearTailDistribution.range(
            primaryStat: agility,
            opposingStat: instinct,
            multiplier: multiplier,
            peakPosition: GameMechanicsConstants.dodgePeakPosition,
            peakWeightShare: GameMechanicsConstants.dodgePeakWeight
        )
        return DodgeDistribution(
            minimumChance: Int16(range.minimum),
            maximumChance: Int16(range.maximum),
            rangeValues: range.values,
            rangeWeights: range.weights
        )
    }
}

//
//  ElfCritService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Dependencies

/// Default `CritService` implementation. Three stages:
/// 1. Select crit chance from the peak+linear-tail distribution.
/// 2. Resolve success via `ChanceRollService` (auto-fail/auto-success edges).
/// 3. If success, pick a damage multiplier from the fixed distribution.
public final class ElfCritService: CritService {

    private let distributionStrategy: any CritDistributionStrategy
    private let multiplierDistribution: CritMultiplierDistribution
    private let weightedSampling: any WeightedSamplingService
    private let chanceRoll: any ChanceRollService

    public init() {
        @Dependency(\.critDistributionStrategy) var distributionStrategy
        @Dependency(\.critMultiplierDistribution) var multiplierDistribution
        @Dependency(\.weightedSamplingService) var weightedSampling
        @Dependency(\.chanceRollService) var chanceRoll
        self.distributionStrategy = distributionStrategy
        self.multiplierDistribution = multiplierDistribution
        self.weightedSampling = weightedSampling
        self.chanceRoll = chanceRoll
    }

    public func calculateCrit(power: Int16, instinct: Int16, attackerLevel: Int, using generator: WithRandomNumberGenerator) -> CritCalculationResult {
        let distribution = distributionStrategy.distribution(
            power: power,
            instinct: instinct,
            attackerLevel: attackerLevel
        )
        let selectedChance = weightedSampling.sample(
            values: distribution.rangeValues,
            weights: distribution.rangeWeights,
            using: generator
        ) ?? distribution.minimumChance

        let (stage2Roll, success) = chanceRoll.resolve(chance: selectedChance, using: generator)

        let selectedMultiplier = selectMultiplier(
            critSuccess: success,
            from: multiplierDistribution,
            using: generator
        )

        return CritCalculationResult(
            distribution: distribution,
            selectedChance: selectedChance,
            stage2Roll: stage2Roll,
            success: success,
            selectedMultiplier: selectedMultiplier
        )
    }

    /// Picks a damage multiplier. Returns `1.0` on crit failure or empty
    /// distribution; otherwise a weighted sample from the distribution.
    private func selectMultiplier(
        critSuccess: Bool,
        from distribution: CritMultiplierDistribution,
        using generator: WithRandomNumberGenerator
    ) -> Double {
        guard critSuccess else { return 1.0 }
        return weightedSampling.sample(
            values: distribution.values,
            weights: distribution.weights,
            using: generator
        ) ?? 1.0
    }
}

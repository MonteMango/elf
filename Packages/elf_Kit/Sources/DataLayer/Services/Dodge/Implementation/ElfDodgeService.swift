//
//  ElfDodgeService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import Dependencies

/// Default `DodgeService` implementation. Selects a chance from the
/// peak+linear-tail distribution via `WeightedSamplingService`, then resolves
/// success via shared `ChanceRollService` (handles 0 / 100 edge cases).
public final class ElfDodgeService: DodgeService {

    private let distributionStrategy: any DodgeDistributionStrategy
    private let weightedSampling: any WeightedSamplingService
    private let chanceRoll: any ChanceRollService

    public init() {
        @Dependency(\.dodgeDistributionStrategy) var distributionStrategy
        @Dependency(\.weightedSamplingService) var weightedSampling
        @Dependency(\.chanceRollService) var chanceRoll
        self.distributionStrategy = distributionStrategy
        self.weightedSampling = weightedSampling
        self.chanceRoll = chanceRoll
    }

    public func calculateDodge(agility: Int16, instinct: Int16, attackerLevel: Int, using generator: WithRandomNumberGenerator) -> DodgeCalculationResult {
        let distribution = distributionStrategy.distribution(
            agility: agility,
            instinct: instinct,
            attackerLevel: attackerLevel
        )
        let selectedChance = weightedSampling.sample(
            values: distribution.rangeValues,
            weights: distribution.rangeWeights,
            using: generator
        ) ?? distribution.minimumChance

        let (stage2Roll, success) = chanceRoll.resolve(chance: selectedChance, using: generator)

        return DodgeCalculationResult(
            distribution: distribution,
            selectedChance: selectedChance,
            stage2Roll: stage2Roll,
            success: success
        )
    }
}

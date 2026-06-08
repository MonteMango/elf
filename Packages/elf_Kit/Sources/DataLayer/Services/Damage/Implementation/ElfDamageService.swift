//
//  ElfDamageService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Dependencies
import Foundation

public final class ElfDamageService: DamageService {

    private let itemsRepository: any ItemsRepository
    private let strengthDistributionStrategy: any StrengthDamageDistributionStrategy
    private let damageReductionDistributionStrategy: any DamageReductionDistributionStrategy
    private let weightedSampling: any WeightedSamplingService

    public init() {
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.strengthDamageDistributionStrategy) var strengthDistributionStrategy
        @Dependency(\.damageReductionDistributionStrategy) var damageReductionDistributionStrategy
        @Dependency(\.weightedSamplingService) var weightedSampling
        self.itemsRepository = itemsRepository
        self.strengthDistributionStrategy = strengthDistributionStrategy
        self.damageReductionDistributionStrategy = damageReductionDistributionStrategy
        self.weightedSampling = weightedSampling
    }

    public func getWeaponDamage(weaponId: UUID?) -> (minDmg: Int16, maxDmg: Int16)? {
        // No weapon equipped
        guard let weaponId = weaponId else {
            return (minDmg: 0, maxDmg: 0)
        }

        // Fetch weapon item
        guard let item = itemsRepository.getHeroItem(weaponId),
              let weapon = item as? WeaponItem else {
            // Item not found or not a weapon
            return (minDmg: 0, maxDmg: 0)
        }

        return (minDmg: weapon.minimumAttackPoint, maxDmg: weapon.maximumAttackPoint)
    }

    public func getRandomStrengthDamage(_ strengthAttribute: Int16, using generator: WithRandomNumberGenerator) -> Int16 {
        weightedRoll(from: strengthDistributionStrategy.distribution(for: strengthAttribute), using: generator)
    }

    public func getRandomDamageReduction(stat: Int16, coefficient: Double, using generator: WithRandomNumberGenerator) -> Int16 {
        weightedRoll(from: damageReductionDistributionStrategy.distribution(for: stat, coefficient: coefficient), using: generator)
    }

    private func weightedRoll(from distribution: DamageDistribution, using generator: WithRandomNumberGenerator) -> Int16 {
        weightedSampling.sample(values: distribution.values, weights: distribution.weights, using: generator) ?? 0
    }

    public func calculateTotalDamage(from pointStatus: [BodyPart: PointStatus]) -> Int {
        // Single source of truth lives on `PointStatus.damageTakenValue` so the
        // production damage path and the diagnostics aggregator can never
        // drift. Per-case math (weapon × crit multiplier, weakBlocked's
        // pre-halved final, clamp at 0) is encoded there.
        pointStatus.values.reduce(0) { $0 + $1.damageTakenValue }
    }
}

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
    private let enduranceDistributionStrategy: any EnduranceDamageReductionDistributionStrategy

    public init() {
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.strengthDamageDistributionStrategy) var strengthDistributionStrategy
        @Dependency(\.enduranceDamageReductionDistributionStrategy) var enduranceDistributionStrategy
        self.itemsRepository = itemsRepository
        self.strengthDistributionStrategy = strengthDistributionStrategy
        self.enduranceDistributionStrategy = enduranceDistributionStrategy
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

    public func getRandomStrengthDamage(_ strengthAttribute: Int16) -> Int16 {
        weightedRoll(from: strengthDistributionStrategy.distribution(for: strengthAttribute))
    }

    public func getRandomEnduranceDamageReduction(_ enduranceAttribute: Int16) -> Int16 {
        weightedRoll(from: enduranceDistributionStrategy.distribution(for: enduranceAttribute))
    }

    private func weightedRoll(from distribution: DamageDistribution) -> Int16 {
        let totalWeight = distribution.weights.reduce(0, +)

        // If total weight is 0, return 0 (edge case)
        guard totalWeight > 0 else {
            return 0
        }

        let randomValue = Int.random(in: 0..<totalWeight)

        var cumulativeWeight = 0
        for (index, weight) in distribution.weights.enumerated() {
            cumulativeWeight += weight
            if randomValue < cumulativeWeight {
                return distribution.values[index]
            }
        }

        // Fallback (should never reach here)
        return distribution.values.last ?? 0
    }

    public func calculateTotalDamage(from pointStatus: [BodyPart: PointStatus]) -> Int {
        // Single source of truth lives on `PointStatus.damageTakenValue` so the
        // production damage path and the diagnostics aggregator can never
        // drift. Per-case math (weapon × crit multiplier, weakBlocked's
        // pre-halved final, clamp at 0) is encoded there.
        pointStatus.values.reduce(0) { $0 + $1.damageTakenValue }
    }
}

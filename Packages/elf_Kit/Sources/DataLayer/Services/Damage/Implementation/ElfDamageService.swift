//
//  ElfDamageService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public final class ElfDamageService: DamageService {

    private let distributionStrategy: StrengthDamageDistributionStrategy
    private let itemsRepository: ItemsRepository

    public init(
        itemsRepository: ItemsRepository,
        distributionStrategy: StrengthDamageDistributionStrategy = ElfStrengthDamageDistributionStrategy()
    ) {
        self.itemsRepository = itemsRepository
        self.distributionStrategy = distributionStrategy
    }
    
    public func getMinMaxStrengthDamage(_ strengthAttribute: Int16) async -> (minDmg: Int16, maxDmg: Int16)? {
        let dmgStrengthDistribution = distributionStrategy.distribution(for: strengthAttribute)
        guard
            let minDmg = dmgStrengthDistribution.values.first,
            let maxDmg = dmgStrengthDistribution.values.last
        else { return nil }

        return (minDmg: minDmg, maxDmg: maxDmg)
    }

    public func getStrengthDamageDistribution(_ strengthAttribute: Int16) async -> (distribution: [Int16], weights: [Int]) {
        let dmgStrengthDistribution = distributionStrategy.distribution(for: strengthAttribute)
        return (distribution: dmgStrengthDistribution.values, weights: dmgStrengthDistribution.weights)
    }

    public func getWeaponDamage(weaponId: UUID?) async -> (minDmg: Int16, maxDmg: Int16)? {
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

    public func getRandomStrengthDamage(_ strengthAttribute: Int16) async -> Int16 {
        // Get distribution from strategy
        let distribution = distributionStrategy.distribution(for: strengthAttribute)

        // Calculate total weight
        let totalWeight = distribution.weights.reduce(0, +)

        // If total weight is 0, return 0 (edge case)
        guard totalWeight > 0 else {
            return 0
        }

        // Generate random number in range [0, totalWeight)
        let randomValue = Int.random(in: 0..<totalWeight)

        // Find which value corresponds to this random weight
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

    public func getRandomWeaponDamage(weaponId: UUID?) async -> Int16 {
        // Get weapon damage range
        guard let weaponDamage = await getWeaponDamage(weaponId: weaponId) else {
            return 0
        }

        // Return random value in range [minDamage, maxDamage]
        return Int16.random(in: weaponDamage.minDmg...weaponDamage.maxDmg)
    }

    public func calculateTotalDamage(from pointStatus: [BodyPart: PointStatus]) -> Int {
        var totalDamage = 0

        for (_, status) in pointStatus {
            switch status {
            case .hit(let damage), .critHit(let damage):
                totalDamage += damage
            case .blocked, .dodged, .nothing:
                break
            }
        }

        return totalDamage
    }
}

// MARK: - Sendable Conformance
extension ElfDamageService: @unchecked Sendable {}

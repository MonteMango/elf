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
    private let distributionStrategy: any StrengthDamageDistributionStrategy

    public init() {
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.strengthDamageDistributionStrategy) var distributionStrategy
        self.itemsRepository = itemsRepository
        self.distributionStrategy = distributionStrategy
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

    public func calculateTotalDamage(from pointStatus: [BodyPart: PointStatus]) -> Int {
        var totalDamage = 0

        for (_, status) in pointStatus {
            switch status {
            case .hit(let weaponDamage, let strengthDamage, let defenderArmor):
                let damage = max(0, weaponDamage + strengthDamage - defenderArmor)
                totalDamage += damage
            case .critHit(let weaponDamage, let strengthDamage, let defenderArmor, let multiplier):
                let baseDamage = weaponDamage + strengthDamage
                let damage = max(0, Int(Double(baseDamage) * multiplier) - defenderArmor)
                totalDamage += damage
            case .blocked, .dodged, .nothing:
                // No damage for blocked, dodged, or nothing
                break
            }
        }

        return totalDamage
    }
}

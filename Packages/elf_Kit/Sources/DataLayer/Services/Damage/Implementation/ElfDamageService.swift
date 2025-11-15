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

    public func getWeaponDamage(weaponId: UUID?) async -> (minDmg: Int16, maxDmg: Int16)? {
        // No weapon equipped
        guard let weaponId = weaponId else {
            return (minDmg: 0, maxDmg: 0)
        }

        // Fetch weapon item
        guard let item = await itemsRepository.getHeroItem(weaponId),
              let weapon = item as? WeaponItem else {
            // Item not found or not a weapon
            return (minDmg: 0, maxDmg: 0)
        }

        return (minDmg: weapon.minimumAttackPoint, maxDmg: weapon.maximumAttackPoint)
    }
}

// MARK: - Sendable Conformance
extension ElfDamageService: @unchecked Sendable {}

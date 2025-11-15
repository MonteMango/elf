//
//  ElfDamageService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public final class ElfDamageService: DamageService {
    
    private let distributionStrategy: StrengthDamageDistributionStrategy
    
    public init(distributionStrategy: StrengthDamageDistributionStrategy = ElfStrengthDamageDistributionStrategy()) {
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
}

// MARK: - Sendable Conformance
extension ElfDamageService: @unchecked Sendable {}

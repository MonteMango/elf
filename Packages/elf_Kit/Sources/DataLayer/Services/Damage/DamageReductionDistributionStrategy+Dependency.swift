//
//  DamageReductionDistributionStrategy+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var damageReductionDistributionStrategy: any DamageReductionDistributionStrategy {
        get { self[DamageReductionDistributionStrategyKey.self] }
        set { self[DamageReductionDistributionStrategyKey.self] = newValue }
    }
}

private enum DamageReductionDistributionStrategyKey: DependencyKey {
    static var liveValue: any DamageReductionDistributionStrategy {
        ElfDamageReductionDistributionStrategy()
    }
}

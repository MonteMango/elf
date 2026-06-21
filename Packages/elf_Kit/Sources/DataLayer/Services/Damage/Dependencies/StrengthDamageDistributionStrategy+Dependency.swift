//
//  StrengthDamageDistributionStrategy+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var strengthDamageDistributionStrategy: any StrengthDamageDistributionStrategy {
        get { self[StrengthDamageDistributionStrategyKey.self] }
        set { self[StrengthDamageDistributionStrategyKey.self] = newValue }
    }
}

private enum StrengthDamageDistributionStrategyKey: DependencyKey {
    static var liveValue: any StrengthDamageDistributionStrategy {
        ElfStrengthDamageDistributionStrategy()
    }
}

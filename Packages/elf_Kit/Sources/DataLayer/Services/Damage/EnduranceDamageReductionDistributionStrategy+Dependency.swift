//
//  EnduranceDamageReductionDistributionStrategy+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var enduranceDamageReductionDistributionStrategy: any EnduranceDamageReductionDistributionStrategy {
        get { self[EnduranceDamageReductionDistributionStrategyKey.self] }
        set { self[EnduranceDamageReductionDistributionStrategyKey.self] = newValue }
    }
}

private enum EnduranceDamageReductionDistributionStrategyKey: DependencyKey {
    static var liveValue: any EnduranceDamageReductionDistributionStrategy {
        ElfEnduranceDamageReductionDistributionStrategy()
    }
}

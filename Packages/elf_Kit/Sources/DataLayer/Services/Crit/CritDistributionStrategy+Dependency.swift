//
//  CritDistributionStrategy+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var critDistributionStrategy: any CritDistributionStrategy {
        get { self[CritDistributionStrategyKey.self] }
        set { self[CritDistributionStrategyKey.self] = newValue }
    }
}

private enum CritDistributionStrategyKey: DependencyKey {
    static var liveValue: any CritDistributionStrategy {
        ElfCritDistributionStrategy()
    }
}

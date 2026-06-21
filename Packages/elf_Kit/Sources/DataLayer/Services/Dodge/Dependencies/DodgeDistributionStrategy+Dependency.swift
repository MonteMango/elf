//
//  DodgeDistributionStrategy+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var dodgeDistributionStrategy: any DodgeDistributionStrategy {
        get { self[DodgeDistributionStrategyKey.self] }
        set { self[DodgeDistributionStrategyKey.self] = newValue }
    }
}

private enum DodgeDistributionStrategyKey: DependencyKey {
    static var liveValue: any DodgeDistributionStrategy {
        ElfDodgeDistributionStrategy()
    }
}

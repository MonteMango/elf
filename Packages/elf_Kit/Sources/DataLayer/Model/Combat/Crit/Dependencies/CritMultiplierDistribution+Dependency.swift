//
//  CritMultiplierDistribution+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var critMultiplierDistribution: CritMultiplierDistribution {
        get { self[CritMultiplierDistributionKey.self] }
        set { self[CritMultiplierDistributionKey.self] = newValue }
    }
}

private enum CritMultiplierDistributionKey: DependencyKey {
    static var liveValue: CritMultiplierDistribution { CritMultiplierDistribution() }
}

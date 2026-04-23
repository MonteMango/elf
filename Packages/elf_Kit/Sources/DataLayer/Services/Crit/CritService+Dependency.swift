//
//  CritService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var critService: any CritService {
        get { self[CritServiceKey.self] }
        set { self[CritServiceKey.self] = newValue }
    }
}

private enum CritServiceKey: DependencyKey {
    static var liveValue: any CritService {
        ElfCritService(distributionStrategy: ElfCritDistributionStrategy())
    }
}

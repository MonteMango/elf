//
//  MiningService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var miningService: any MiningService {
        get { self[MiningServiceKey.self] }
        set { self[MiningServiceKey.self] = newValue }
    }
}

private enum MiningServiceKey: DependencyKey {
    static var liveValue: any MiningService {
        @Dependency(\.gatheringEngine) var gatheringEngine
        @Dependency(\.skillProgressCalculator) var skillProgressCalculator
        return DefaultMiningService(
            gatheringEngine: gatheringEngine,
            skillProgressCalculator: skillProgressCalculator
        )
    }
}

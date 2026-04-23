//
//  FishingService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var fishingService: any FishingService {
        get { self[FishingServiceKey.self] }
        set { self[FishingServiceKey.self] = newValue }
    }
}

private enum FishingServiceKey: DependencyKey {
    static var liveValue: any FishingService {
        @Dependency(\.gatheringEngine) var gatheringEngine
        @Dependency(\.skillProgressCalculator) var skillProgressCalculator
        return DefaultFishingService(
            gatheringEngine: gatheringEngine,
            skillProgressCalculator: skillProgressCalculator
        )
    }
}

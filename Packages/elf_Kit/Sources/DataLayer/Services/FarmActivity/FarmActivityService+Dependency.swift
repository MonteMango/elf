//
//  FarmActivityService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var farmActivityService: any FarmActivityService {
        get { self[FarmActivityServiceKey.self] }
        set { self[FarmActivityServiceKey.self] = newValue }
    }
}

private enum FarmActivityServiceKey: DependencyKey {
    static var liveValue: any FarmActivityService {
        @Dependency(\.fishingService) var fishingService
        @Dependency(\.foragingService) var foragingService
        @Dependency(\.miningService) var miningService
        @Dependency(\.fishRepository) var fishRepository
        @Dependency(\.herbRepository) var herbRepository
        @Dependency(\.oreRepository) var oreRepository
        @Dependency(\.progressionService) var progressionService
        return DefaultFarmActivityService(
            fishingService: fishingService,
            foragingService: foragingService,
            miningService: miningService,
            fishRepository: fishRepository,
            herbRepository: herbRepository,
            oreRepository: oreRepository,
            progressionService: progressionService
        )
    }
}

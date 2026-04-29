//
//  DefaultFarmActivityService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Default implementation of FarmActivityService
/// Delegates to specific services (FishingService, ForagingService, MiningService)
public final class DefaultFarmActivityService: FarmActivityService {

    // MARK: - Constants

    private let farmExpPerLevel = 50

    // MARK: - Dependencies (snapshotted at init)

    private let fishingService: any FishingService
    private let foragingService: any ForagingService
    private let miningService: any MiningService
    private let fishRepository: any Repository<Fish>
    private let herbRepository: any Repository<Herb>
    private let oreRepository: any Repository<Ore>
    private let progressionService: any ProgressionService

    // MARK: - Initialization

    public init() {
        @Dependency(\.fishingService) var fishingService
        @Dependency(\.foragingService) var foragingService
        @Dependency(\.miningService) var miningService
        @Dependency(\.fishRepository) var fishRepository
        @Dependency(\.herbRepository) var herbRepository
        @Dependency(\.oreRepository) var oreRepository
        @Dependency(\.progressionService) var progressionService
        self.fishingService = fishingService
        self.foragingService = foragingService
        self.miningService = miningService
        self.fishRepository = fishRepository
        self.herbRepository = herbRepository
        self.oreRepository = oreRepository
        self.progressionService = progressionService
    }

    // MARK: - FarmActivityService

    public func perform(
        activity: FarmActivity,
        currentExp: Int,
        expPerLevel: Int
    ) -> FarmActivityResult {
        switch activity {
        case .fishing:
            let result = fishingService.performFishing(
                availableFish: fishRepository.getAll(),
                currentExp: currentExp,
                expPerLevel: expPerLevel
            )
            return .fishing(result)

        case .foraging:
            let result = foragingService.performForaging(
                availableHerbs: herbRepository.getAll(),
                currentExp: currentExp,
                expPerLevel: expPerLevel
            )
            return .foraging(result)

        case .mining:
            let result = miningService.performMining(
                availableOres: oreRepository.getAll(),
                currentExp: currentExp,
                expPerLevel: expPerLevel
            )
            return .mining(result)
        }
    }

    public func getAvailableItems(for activity: FarmActivity) -> [FarmActivityItem] {
        switch activity {
        case .fishing:
            return fishRepository.getAll().asFarmActivityItems
        case .foraging:
            return herbRepository.getAll().asFarmActivityItems
        case .mining:
            return oreRepository.getAll().asFarmActivityItems
        }
    }

    public func getSkillInfo(for activity: FarmActivity, exp: Int) -> FarmSkillInfo {
        FarmSkillInfo(
            title: "\(activity.title) skill",
            level: progressionService.farmingLevel(exp: exp),
            progress: progressionService.farmingProgress(exp: exp),
            expInLevel: exp % farmExpPerLevel,
            expPerLevel: farmExpPerLevel
        )
    }

}

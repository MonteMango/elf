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

    // MARK: - Dependencies

    @Dependency(\.fishingService) private var fishingService
    @Dependency(\.foragingService) private var foragingService
    @Dependency(\.miningService) private var miningService
    @Dependency(\.fishRepository) private var fishRepository
    @Dependency(\.herbRepository) private var herbRepository
    @Dependency(\.oreRepository) private var oreRepository
    @Dependency(\.progressionService) private var progressionService

    // MARK: - Initialization

    public init() {}

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

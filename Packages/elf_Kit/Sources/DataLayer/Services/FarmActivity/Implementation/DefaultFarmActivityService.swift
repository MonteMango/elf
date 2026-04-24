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

    private let _fishingService = Dependency(\.fishingService)
    private var fishingService: any FishingService { _fishingService.wrappedValue }

    private let _foragingService = Dependency(\.foragingService)
    private var foragingService: any ForagingService { _foragingService.wrappedValue }

    private let _miningService = Dependency(\.miningService)
    private var miningService: any MiningService { _miningService.wrappedValue }

    private let _fishRepository = Dependency(\.fishRepository)
    private var fishRepository: any Repository<Fish> { _fishRepository.wrappedValue }

    private let _herbRepository = Dependency(\.herbRepository)
    private var herbRepository: any Repository<Herb> { _herbRepository.wrappedValue }

    private let _oreRepository = Dependency(\.oreRepository)
    private var oreRepository: any Repository<Ore> { _oreRepository.wrappedValue }

    private let _progressionService = Dependency(\.progressionService)
    private var progressionService: any ProgressionService { _progressionService.wrappedValue }

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

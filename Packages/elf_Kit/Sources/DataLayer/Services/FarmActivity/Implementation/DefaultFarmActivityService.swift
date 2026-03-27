//
//  DefaultFarmActivityService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Default implementation of FarmActivityService
/// Delegates to specific services (FishingService, ForagingService, MiningService)
public final class DefaultFarmActivityService: FarmActivityService {

    // MARK: - Constants

    private let farmExpPerLevel = 50

    // MARK: - Dependencies

    private let fishingService: any FishingService
    private let foragingService: any ForagingService
    private let miningService: any MiningService
    private let fishRepository: any Repository<Fish>
    private let herbRepository: any Repository<Herb>
    private let oreRepository: any Repository<Ore>
    private let progressionService: any ProgressionService

    // MARK: - Initialization

    public init(
        fishingService: any FishingService,
        foragingService: any ForagingService,
        miningService: any MiningService,
        fishRepository: any Repository<Fish>,
        herbRepository: any Repository<Herb>,
        oreRepository: any Repository<Ore>,
        progressionService: any ProgressionService
    ) {
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
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) async -> FarmActivityResult {
        switch activity {
        case .fishing:
            let result = fishingService.performFishing(
                availableFish: await fishRepository.getAll(),
                currentLevel: currentLevel,
                currentExp: currentExp,
                expPerLevel: expPerLevel
            )
            return .fishing(result)

        case .foraging:
            let result = foragingService.performForaging(
                availableHerbs: await herbRepository.getAll(),
                currentLevel: currentLevel,
                currentExp: currentExp,
                expPerLevel: expPerLevel
            )
            return .foraging(result)

        case .mining:
            let result = miningService.performMining(
                availableOres: await oreRepository.getAll(),
                currentLevel: currentLevel,
                currentExp: currentExp,
                expPerLevel: expPerLevel
            )
            return .mining(result)
        }
    }

    public func getAvailableItems(for activity: FarmActivity) async -> [FarmActivityItem] {
        switch activity {
        case .fishing:
            return await fishRepository.getAll().asFarmActivityItems
        case .foraging:
            return await herbRepository.getAll().asFarmActivityItems
        case .mining:
            return await oreRepository.getAll().asFarmActivityItems
        }
    }

    public func getSkillInfo(for activity: FarmActivity, player: ElfInfo) -> FarmSkillInfo {
        let (exp, title) = switch activity {
        case .fishing: (player.fishingExp, "\(activity.title) skill")
        case .foraging: (player.foragingExp, "\(activity.title) skill")
        case .mining: (player.miningExp, "\(activity.title) skill")
        }

        return FarmSkillInfo(
            title: title,
            level: progressionService.farmingLevel(exp: exp),
            progress: progressionService.farmingProgress(exp: exp),
            expInLevel: exp % farmExpPerLevel,
            expPerLevel: farmExpPerLevel
        )
    }

    @MainActor
    public func applyResult(_ result: FarmActivityResult, to gameService: any GameStateService) {
        switch result {
        case .fishing(let fishingResult):
            gameService.addFishingExperience(fishingResult.skillProgress.experienceGained)
            gameService.addFishToInventory(fishingResult.caughtFish)

        case .foraging(let foragingResult):
            gameService.addForagingExperience(foragingResult.skillProgress.experienceGained)
            gameService.addHerbsToInventory(foragingResult.gatheredHerbs)

        case .mining(let miningResult):
            gameService.addMiningExperience(miningResult.skillProgress.experienceGained)
            gameService.addOresToInventory(miningResult.minedOres)
        }
    }
}

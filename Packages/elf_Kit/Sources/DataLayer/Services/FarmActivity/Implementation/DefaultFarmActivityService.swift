//
//  DefaultFarmActivityService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Default implementation of FarmActivityService
/// Delegates to specific services (FishingService, ForagingService, MiningService)
@MainActor
public final class DefaultFarmActivityService: FarmActivityService {

    // MARK: - Dependencies

    private let fishingService: any FishingService
    private let foragingService: any ForagingService
    private let miningService: any MiningService
    private let fishRepository: any FishRepository
    private let herbRepository: any HerbRepository
    private let oreRepository: any OreRepository

    // MARK: - Initialization

    public init(
        fishingService: any FishingService,
        foragingService: any ForagingService,
        miningService: any MiningService,
        fishRepository: any FishRepository,
        herbRepository: any HerbRepository,
        oreRepository: any OreRepository
    ) {
        self.fishingService = fishingService
        self.foragingService = foragingService
        self.miningService = miningService
        self.fishRepository = fishRepository
        self.herbRepository = herbRepository
        self.oreRepository = oreRepository
    }

    // MARK: - FarmActivityService

    public func perform(
        activity: FarmActivity,
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) -> FarmActivityResult {
        switch activity {
        case .fishing:
            let result = fishingService.performFishing(
                areaId: "forest_pond",
                availableFish: fishRepository.getAllFish(),
                currentLevel: currentLevel,
                currentExp: currentExp,
                expPerLevel: expPerLevel
            )
            return .fishing(result)

        case .foraging:
            let result = foragingService.performForaging(
                areaId: "forest_glade",
                availableHerbs: herbRepository.getAllHerbs(),
                currentLevel: currentLevel,
                currentExp: currentExp,
                expPerLevel: expPerLevel
            )
            return .foraging(result)

        case .mining:
            let result = miningService.performMining(
                areaId: "crystal_cave",
                availableOres: oreRepository.getAllOres(),
                currentLevel: currentLevel,
                currentExp: currentExp,
                expPerLevel: expPerLevel
            )
            return .mining(result)
        }
    }

    public func getAvailableItems(for activity: FarmActivity) -> [FarmActivityItem] {
        switch activity {
        case .fishing:
            return fishRepository.getAllFish().asFarmActivityItems
        case .foraging:
            return herbRepository.getAllHerbs().asFarmActivityItems
        case .mining:
            return oreRepository.getAllOres().asFarmActivityItems
        }
    }

    public func getSkillInfo(for activity: FarmActivity, player: ElfInfo) -> FarmSkillInfo {
        FarmSkillInfo.make(for: activity, player: player)
    }

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

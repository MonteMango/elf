//
//  DefaultFishingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class DefaultFishingService: FishingService {

    // MARK: - Dependencies

    private let gatheringEngine: any GatheringEngine
    private let skillProgressCalculator: any SkillProgressCalculator

    // MARK: - Initialization

    public init(
        gatheringEngine: any GatheringEngine,
        skillProgressCalculator: any SkillProgressCalculator
    ) {
        self.gatheringEngine = gatheringEngine
        self.skillProgressCalculator = skillProgressCalculator
    }

    // MARK: - FishingService

    public func performFishing(
        availableFish: [Fish],
        currentExp: Int,
        expPerLevel: Int
    ) -> FishingResult {
        let caughtFish = gatheringEngine.gather(from: availableFish)

        // Calculate skill progress from gathered fish
        let skillProgress = skillProgressCalculator.calculateFromGathered(
            caughtFish,
            skillName: "Fishing",
            currentExp: currentExp,
            expPerLevel: expPerLevel
        )

        return FishingResult(
            caughtFish: caughtFish,
            skillProgress: skillProgress
        )
    }
}

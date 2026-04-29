//
//  DefaultFishingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

public final class DefaultFishingService: FishingService {

    // MARK: - Dependencies (snapshotted at init)

    private let gatheringEngine: any GatheringEngine
    private let skillProgressCalculator: any SkillProgressCalculator

    // MARK: - Initialization

    public init() {
        @Dependency(\.gatheringEngine) var gatheringEngine
        @Dependency(\.skillProgressCalculator) var skillProgressCalculator
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

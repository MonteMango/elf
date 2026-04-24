//
//  DefaultFishingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

public final class DefaultFishingService: FishingService {

    // MARK: - Dependencies

    @Dependency(\.gatheringEngine) private var gatheringEngine
    @Dependency(\.skillProgressCalculator) private var skillProgressCalculator

    // MARK: - Initialization

    public init() {}

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

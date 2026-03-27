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
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) async -> FishingResult {
        // Use unified gathering engine (uses GatheringEngine.defaultMaxCount)
        let caughtFish = await gatheringEngine.gather(from: availableFish, maxCount: DefaultGatheringEngine.defaultMaxCount)

        // Calculate skill progress from gathered fish
        let skillProgress = skillProgressCalculator.calculateFromGathered(
            caughtFish,
            skillName: "Fishing",
            currentLevel: currentLevel,
            currentExp: currentExp,
            expPerLevel: expPerLevel
        )

        return FishingResult(
            caughtFish: caughtFish,
            skillProgress: skillProgress
        )
    }
}

// MARK: - Sendable Conformance
// Thread-safe: Stateless class with no mutable stored properties.
extension DefaultFishingService: Sendable {}

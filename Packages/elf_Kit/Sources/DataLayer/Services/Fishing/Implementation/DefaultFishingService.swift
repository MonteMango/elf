//
//  DefaultFishingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class DefaultFishingService: FishingService {

    // MARK: - Dependencies

    private let skillProgressCalculator: any SkillProgressCalculator

    // MARK: - Initialization

    public init(skillProgressCalculator: any SkillProgressCalculator) {
        self.skillProgressCalculator = skillProgressCalculator
    }

    // MARK: - FishingService

    public func performFishing(
        availableFish: [Fish],
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) -> FishingResult {
        // Use unified gathering engine (uses GatheringEngine.defaultMaxCount)
        let caughtFish = GatheringEngine.gather(from: availableFish)

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

//
//  DefaultFishingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class DefaultFishingService: FishingService {

    // MARK: - Initialization

    public init() {}

    // MARK: - FishingService

    public func performFishing(
        areaId: String,
        availableFish: [Fish],
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) -> FishingResult {
        // Use unified gathering engine (uses GatheringEngine.defaultMaxCount)
        let caughtFish = GatheringEngine.gather(from: availableFish)

        // Calculate fishing XP gained based on GatherableTier.xpValue
        let expGained = caughtFish.reduce(0) { total, fish in
            total + fish.tier.xpValue
        }

        // Calculate skill progress
        let skillProgress = SkillProgressData.calculate(
            skillName: "Fishing",
            currentLevel: currentLevel,
            currentExp: currentExp,
            expGained: expGained,
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

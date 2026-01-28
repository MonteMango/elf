//
//  DefaultForagingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class DefaultForagingService: ForagingService {

    // MARK: - Initialization

    public init() {}

    // MARK: - ForagingService

    public func performForaging(
        areaId: String,
        availableHerbs: [Herb],
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) -> ForagingResult {
        // Use unified gathering engine (uses GatheringEngine.defaultMaxCount)
        let gatheredHerbs = GatheringEngine.gather(from: availableHerbs)

        // Calculate foraging XP gained based on GatherableTier.xpValue
        let expGained = gatheredHerbs.reduce(0) { total, herb in
            total + herb.tier.xpValue
        }

        // Calculate skill progress
        let skillProgress = SkillProgressData.calculate(
            skillName: "Foraging",
            currentLevel: currentLevel,
            currentExp: currentExp,
            expGained: expGained,
            expPerLevel: expPerLevel
        )

        return ForagingResult(
            gatheredHerbs: gatheredHerbs,
            skillProgress: skillProgress
        )
    }
}

// MARK: - Sendable Conformance
// Thread-safe: Stateless class with no mutable stored properties.
extension DefaultForagingService: Sendable {}

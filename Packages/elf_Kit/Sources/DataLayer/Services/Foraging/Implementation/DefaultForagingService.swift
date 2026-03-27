//
//  DefaultForagingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class DefaultForagingService: ForagingService {

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

    // MARK: - ForagingService

    public func performForaging(
        availableHerbs: [Herb],
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) async -> ForagingResult {
        // Use unified gathering engine (uses GatheringEngine.defaultMaxCount)
        let gatheredHerbs = await gatheringEngine.gather(from: availableHerbs, maxCount: DefaultGatheringEngine.defaultMaxCount)

        // Calculate skill progress from gathered herbs
        let skillProgress = await skillProgressCalculator.calculateFromGathered(
            gatheredHerbs,
            skillName: "Foraging",
            currentLevel: currentLevel,
            currentExp: currentExp,
            expPerLevel: expPerLevel
        )

        return ForagingResult(
            gatheredHerbs: gatheredHerbs,
            skillProgress: skillProgress
        )
    }
}
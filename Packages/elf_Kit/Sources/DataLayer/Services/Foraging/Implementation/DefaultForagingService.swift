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
        currentExp: Int,
        expPerLevel: Int
    ) -> ForagingResult {
        let gatheredHerbs = gatheringEngine.gather(from: availableHerbs)

        // Calculate skill progress from gathered herbs
        let skillProgress = skillProgressCalculator.calculateFromGathered(
            gatheredHerbs,
            skillName: "Foraging",
            currentExp: currentExp,
            expPerLevel: expPerLevel
        )

        return ForagingResult(
            gatheredHerbs: gatheredHerbs,
            skillProgress: skillProgress
        )
    }
}

//
//  DefaultMiningService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class DefaultMiningService: MiningService {

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

    // MARK: - MiningService

    public func performMining(
        availableOres: [Ore],
        currentExp: Int,
        expPerLevel: Int
    ) -> MiningResult {
        let minedOres = gatheringEngine.gather(from: availableOres)

        // Calculate skill progress from gathered ores
        let skillProgress = skillProgressCalculator.calculateFromGathered(
            minedOres,
            skillName: "Mining",
            currentExp: currentExp,
            expPerLevel: expPerLevel
        )

        return MiningResult(
            minedOres: minedOres,
            skillProgress: skillProgress
        )
    }
}

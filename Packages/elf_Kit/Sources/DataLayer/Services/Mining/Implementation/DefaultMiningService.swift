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
    ) async -> MiningResult {
        // Use unified gathering engine (uses GatheringEngine.defaultMaxCount)
        let minedOres = await gatheringEngine.gather(from: availableOres, maxCount: DefaultGatheringEngine.defaultMaxCount)

        // Calculate skill progress from gathered ores
        let skillProgress = await skillProgressCalculator.calculateFromGathered(
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
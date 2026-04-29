//
//  DefaultMiningService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

public final class DefaultMiningService: MiningService {

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

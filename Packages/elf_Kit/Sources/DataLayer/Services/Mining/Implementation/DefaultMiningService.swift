//
//  DefaultMiningService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

public final class DefaultMiningService: MiningService {

    // MARK: - Dependencies

    private let _gatheringEngine = Dependency(\.gatheringEngine)
    private var gatheringEngine: any GatheringEngine { _gatheringEngine.wrappedValue }

    private let _skillProgressCalculator = Dependency(\.skillProgressCalculator)
    private var skillProgressCalculator: any SkillProgressCalculator { _skillProgressCalculator.wrappedValue }

    // MARK: - Initialization

    public init() {}

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

//
//  DefaultMiningService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class DefaultMiningService: MiningService {

    // MARK: - Dependencies

    private let skillProgressCalculator: any SkillProgressCalculator

    // MARK: - Initialization

    public init(skillProgressCalculator: any SkillProgressCalculator) {
        self.skillProgressCalculator = skillProgressCalculator
    }

    // MARK: - MiningService

    public func performMining(
        availableOres: [Ore],
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) -> MiningResult {
        // Use unified gathering engine (uses GatheringEngine.defaultMaxCount)
        let minedOres = GatheringEngine.gather(from: availableOres)

        // Calculate skill progress from gathered ores
        let skillProgress = skillProgressCalculator.calculateFromGathered(
            minedOres,
            skillName: "Mining",
            currentLevel: currentLevel,
            currentExp: currentExp,
            expPerLevel: expPerLevel
        )

        return MiningResult(
            minedOres: minedOres,
            skillProgress: skillProgress
        )
    }
}

// MARK: - Sendable Conformance
// Thread-safe: Stateless class with no mutable stored properties.
extension DefaultMiningService: Sendable {}

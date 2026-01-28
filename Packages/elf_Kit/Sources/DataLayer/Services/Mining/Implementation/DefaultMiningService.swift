//
//  DefaultMiningService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class DefaultMiningService: MiningService {

    // MARK: - Initialization

    public init() {}

    // MARK: - MiningService

    public func performMining(
        areaId: String,
        availableOres: [Ore],
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) -> MiningResult {
        // Use unified gathering engine (uses GatheringEngine.defaultMaxCount)
        let minedOres = GatheringEngine.gather(from: availableOres)

        // Calculate mining XP gained based on GatherableTier.xpValue
        let expGained = minedOres.reduce(0) { total, ore in
            total + ore.tier.xpValue
        }

        // Calculate skill progress
        let skillProgress = SkillProgressData.calculate(
            skillName: "Mining",
            currentLevel: currentLevel,
            currentExp: currentExp,
            expGained: expGained,
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

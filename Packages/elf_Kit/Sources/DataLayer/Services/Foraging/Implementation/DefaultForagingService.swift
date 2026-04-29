//
//  DefaultForagingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

public final class DefaultForagingService: ForagingService {

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

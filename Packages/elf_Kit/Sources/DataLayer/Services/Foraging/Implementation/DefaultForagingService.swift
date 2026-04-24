//
//  DefaultForagingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

public final class DefaultForagingService: ForagingService {

    // MARK: - Dependencies

    private let _gatheringEngine = Dependency(\.gatheringEngine)
    private var gatheringEngine: any GatheringEngine { _gatheringEngine.wrappedValue }

    private let _skillProgressCalculator = Dependency(\.skillProgressCalculator)
    private var skillProgressCalculator: any SkillProgressCalculator { _skillProgressCalculator.wrappedValue }

    // MARK: - Initialization

    public init() {}

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

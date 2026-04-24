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

    @Dependency(\.gatheringEngine) private var gatheringEngine
    @Dependency(\.skillProgressCalculator) private var skillProgressCalculator

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

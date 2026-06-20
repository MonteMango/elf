//
//  DefaultBattleResultCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import Dependencies
import Foundation

public final class DefaultBattleResultCalculator: BattleResultCalculator {

    // MARK: - Dependencies (snapshotted at init)

    private let huntService: any HuntService
    private let dropService: any DropService
    private let progressionService: any ProgressionService

    // MARK: - Initialization

    public init() {
        @Dependency(\.huntService) var huntService
        @Dependency(\.dropService) var dropService
        @Dependency(\.progressionService) var progressionService
        self.huntService = huntService
        self.dropService = dropService
        self.progressionService = progressionService
    }

    // MARK: - BattleResultCalculator

    public func calculateResult(
        outcome: BattleOutcome,
        monster: Monster?,
        currentExp: Int
    ) -> ManualBattleResult {
        // Calculate rewards if we have monster data
        var experienceGained = 0
        var drops: [DropItem] = []
        var huntRewards: HuntRewards?

        if let monster = monster {
            let didWin = outcome == .victory
            if didWin {
                let rewards = huntService.calculateRewards(for: monster)
                huntRewards = rewards
                experienceGained = rewards.experience
                drops = dropService.convertToDropItems(rewards: rewards, didWin: didWin)
            }
        }

        let transition = progressionService.experienceTransition(
            previousExp: currentExp,
            gained: experienceGained
        )

        return ManualBattleResult(
            outcome: outcome,
            experienceGained: experienceGained,
            drops: drops,
            huntRewards: huntRewards,
            transition: transition
        )
    }
}

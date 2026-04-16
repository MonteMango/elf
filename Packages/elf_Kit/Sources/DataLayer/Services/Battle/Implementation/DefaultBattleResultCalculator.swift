//
//  DefaultBattleResultCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import Foundation

public final class DefaultBattleResultCalculator: BattleResultCalculator {

    // MARK: - Dependencies

    private let huntService: HuntService
    private let dropService: DropService
    private let progressionService: ProgressionService

    // MARK: - Initialization

    public init(huntService: HuntService, dropService: DropService, progressionService: ProgressionService) {
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

        // XP state before battle
        let previousLevel = progressionService.calculateLevel(currentExp: currentExp)
        let previousExpToNext = progressionService.expToNextLevel(currentExp: currentExp)

        // XP state after battle
        let newExp = currentExp + experienceGained
        let newLevel = progressionService.calculateLevel(currentExp: newExp)
        let newExpToNext = progressionService.expToNextLevel(currentExp: newExp)

        return ManualBattleResult(
            outcome: outcome,
            experienceGained: experienceGained,
            drops: drops,
            huntRewards: huntRewards,
            previousLevel: previousLevel,
            previousExp: currentExp,
            previousExpToNext: previousExpToNext,
            newLevel: newLevel,
            newExp: newExp,
            newExpToNext: newExpToNext
        )
    }
}

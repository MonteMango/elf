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

    // MARK: - Initialization

    public init(huntService: HuntService, dropService: DropService) {
        self.huntService = huntService
        self.dropService = dropService
    }

    // MARK: - BattleResultCalculator

    @MainActor
    public func calculateResult(
        outcome: BattleOutcome,
        monster: Monster?,
        gameService: GameService?
    ) -> ManualBattleResult {
        // Calculate rewards if we have monster data
        var experienceGained = 0
        var drops: [DropItem] = []

        if let monster = monster {
            let didWin = outcome == .victory
            if didWin {
                let rewards = huntService.calculateRewards(for: monster)
                experienceGained = rewards.experience
                drops = dropService.convertToDropItems(rewards: rewards, didWin: didWin)

                // Add drops to player inventory
                gameService?.addDropsToPlayerInventory(rewards: rewards)
            }
        }

        // Get current player XP state (before adding)
        let previousLevel: Int16
        let previousExp: Int
        let previousExpToNext: Int

        if let gameService = gameService {
            let player = gameService.game.player
            previousLevel = player.level
            previousExp = player.currentExp
            previousExpToNext = player.expToNextLevel
        } else {
            // Fallback for non-game battles
            previousLevel = 1
            previousExp = 0
            previousExpToNext = 100
        }

        // Add XP to player if we have game service and won
        if let gameService = gameService, experienceGained > 0 {
            gameService.addPlayerExperience(experienceGained)
        }

        // Save game after battle rewards are applied
        Task {
            try? await gameService?.saveGame()
        }

        // Get new player XP state (after adding)
        let newLevel: Int16
        let newExp: Int
        let newExpToNext: Int

        if let gameService = gameService {
            let player = gameService.game.player
            newLevel = player.level
            newExp = player.currentExp
            newExpToNext = player.expToNextLevel
        } else {
            // Fallback: simulate simple XP addition
            let totalExp = previousExp + experienceGained
            if totalExp >= previousExpToNext {
                newLevel = previousLevel + 1
                newExp = totalExp - previousExpToNext
                newExpToNext = Int(Double(previousExpToNext) * 1.2)
            } else {
                newLevel = previousLevel
                newExp = totalExp
                newExpToNext = previousExpToNext
            }
        }

        // Create battle result
        return ManualBattleResult(
            outcome: outcome,
            experienceGained: experienceGained,
            drops: drops,
            previousLevel: previousLevel,
            previousExp: previousExp,
            previousExpToNext: previousExpToNext,
            newLevel: newLevel,
            newExp: newExp,
            newExpToNext: newExpToNext
        )
    }
}

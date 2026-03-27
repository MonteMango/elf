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

    @MainActor
    public func calculateResult(
        outcome: BattleOutcome,
        monster: Monster?,
        gameService: GameService?
    ) async -> ManualBattleResult {
        // Calculate rewards if we have monster data
        var experienceGained = 0
        var drops: [DropItem] = []

        if let monster = monster {
            let didWin = outcome == .victory
            if didWin {
                let rewards = huntService.calculateRewards(for: monster)
                experienceGained = rewards.experience
                drops = await dropService.convertToDropItems(rewards: rewards, didWin: didWin)

                // Add drops to player inventory
                await gameService?.addDropsToPlayerInventory(rewards: rewards)
            }
        }

        // Get current player XP state (before adding)
        let previousLevel: Int
        let previousExp: Int
        let previousExpToNext: Int

        if let gameService = gameService {
            let player = gameService.game.player
            previousLevel = await progressionService.calculateLevel(currentExp: player.currentExp)
            previousExp = player.currentExp
            previousExpToNext = await progressionService.expToNextLevel(currentExp: player.currentExp)
        } else {
            // Fallback for non-game battles
            previousLevel = 1
            previousExp = 0
            previousExpToNext = 200
        }

        // Add XP to player if we have game service and won
        if let gameService = gameService, experienceGained > 0 {
            gameService.addPlayerExperience(experienceGained)
        }

        // Save game after battle rewards are applied
        Task(priority: .userInitiated) {
            do {
                try await gameService?.saveGame()
            } catch {
                #if DEBUG
                print("[BattleResultCalculator] Failed to save game: \(error)")
                #endif
            }
        }

        // Get new player XP state (after adding)
        let newLevel: Int
        let newExp: Int
        let newExpToNext: Int

        if let gameService = gameService {
            let player = gameService.game.player
            newLevel = await progressionService.calculateLevel(currentExp: player.currentExp)
            newExp = player.currentExp
            newExpToNext = await progressionService.expToNextLevel(currentExp: player.currentExp)
        } else {
            // Fallback: simulate simple XP addition using new formula
            let totalExp = previousExp + experienceGained
            newLevel = max(1, min(12, totalExp / 100))
            newExp = totalExp
            newExpToNext = newLevel < 12 ? (newLevel + 1) * 100 : 0
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

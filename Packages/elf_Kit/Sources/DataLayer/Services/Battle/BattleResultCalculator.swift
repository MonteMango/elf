//
//  BattleResultCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import Foundation

/// Service for calculating battle results including XP, drops, and game state updates
public protocol BattleResultCalculator {
    @MainActor
    func calculateResult(
        outcome: BattleOutcome,
        monster: Monster?,
        gameService: GameService?
    ) async -> ManualBattleResult
}

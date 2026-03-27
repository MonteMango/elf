//
//  BattleResultCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import Foundation

/// Pure calculator for battle results — no side effects, no game state mutations
public protocol BattleResultCalculator: Sendable {
    func calculateResult(
        outcome: BattleOutcome,
        monster: Monster?,
        currentExp: Int
    ) async -> ManualBattleResult
}

//
//  DuelPairingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Service responsible for creating random duel pairs from two teams of combatants.
public protocol DuelPairingService: Sendable {
    /// Creates random duel pairs from alive combatants of both teams.
    /// - Parameters:
    ///   - leftTeam: Array of combatants from the left team
    ///   - rightTeam: Array of combatants from the right team
    ///   - roundNumber: The current round number
    /// - Returns: A BattleRound with randomly paired combatants
    func createRandomPairs(
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        roundNumber: Int
    ) async -> BattleRound
}

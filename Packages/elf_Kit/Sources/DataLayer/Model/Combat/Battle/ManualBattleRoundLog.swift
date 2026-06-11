//
//  ManualBattleRoundLog.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.08.25.
//

import Foundation

public struct ManualBattleRoundLog: Sendable {
    /// Current round number
    public let roundNumber: Int

    /// Actions made by each combatant (key = CombatantSnapshot.id)
    public var action: [CombatantID: BattleRoundAction]

    /// The opponents for current round (could be different in next round)
    public var duels: [(CombatantID, CombatantID)]

    /// Pre calculation for calculation results (key = CombatantSnapshot.id)
    public var calculatedPreResults: [CombatantID: BattleRoundCalculatedPreResult]

    /// The result of the round (key = CombatantSnapshot.id)
    public var results: [CombatantID: BattleRoundResult]

    public init(
        roundNumber: Int,
        action: [CombatantID: BattleRoundAction],
        duels: [(CombatantID, CombatantID)],
        calculatedPreResults: [CombatantID: BattleRoundCalculatedPreResult],
        results: [CombatantID: BattleRoundResult]
    ) {
        self.roundNumber = roundNumber
        self.action = action
        self.duels = duels
        self.calculatedPreResults = calculatedPreResults
        self.results = results
    }
}

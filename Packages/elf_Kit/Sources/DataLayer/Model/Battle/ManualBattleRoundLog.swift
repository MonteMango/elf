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
    public var action: [UUID: BattleRoundAction]

    /// The opponents for current round (could be different in next round)
    public var duels: [(UUID, UUID)]

    /// Pre calculation for calculation results (key = CombatantSnapshot.id)
    public var calculatedPreResults: [UUID: BattleRoundCalculatedPreResult]

    /// The result of the round (key = CombatantSnapshot.id)
    public var results: [UUID: BattleRoundResult]

    public init(
        roundNumber: Int,
        action: [UUID: BattleRoundAction],
        duels: [(UUID, UUID)],
        calculatedPreResults: [UUID: BattleRoundCalculatedPreResult],
        results: [UUID: BattleRoundResult]
    ) {
        self.roundNumber = roundNumber
        self.action = action
        self.duels = duels
        self.calculatedPreResults = calculatedPreResults
        self.results = results
    }
}

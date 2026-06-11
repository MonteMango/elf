//
//  BattleRound.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Represents a single round in a battle with all duel pairs and waiting combatants.
/// Each round, alive combatants are randomly paired for duels.
public struct BattleRound: Sendable, Identifiable, Hashable {
    public let id: UUID

    /// The round number (1-based)
    public let roundNumber: Int

    /// All duel pairs for this round. First pair (index 0) is the active pair controlled by player.
    public let duelPairs: [DuelPair]

    /// IDs of left team combatants waiting without a pair (when teams are unequal)
    public let waitingLeftIds: [CombatantID]

    /// IDs of right team combatants waiting without a pair (when teams are unequal)
    public let waitingRightIds: [CombatantID]

    public init(
        id: UUID = UUID(),
        roundNumber: Int,
        duelPairs: [DuelPair],
        waitingLeftIds: [CombatantID] = [],
        waitingRightIds: [CombatantID] = []
    ) {
        self.id = id
        self.roundNumber = roundNumber
        self.duelPairs = duelPairs
        self.waitingLeftIds = waitingLeftIds
        self.waitingRightIds = waitingRightIds
    }
}

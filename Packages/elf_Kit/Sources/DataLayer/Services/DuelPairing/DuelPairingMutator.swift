//
//  DuelPairingMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Rule family for generating a round's duel pairings, extracted from
/// `BattleFightViewModel` (T16): delegating to `DuelPairingService`, deriving
/// the bot snapshot to display for the hero's duel pair (falling back to the
/// previous displayed snapshot when the hero has no paired opponent this
/// round), and forwarding the round-state debug log. `BattleFightViewModel`
/// stays the owner of round/UI state — it delegates to this mutator and
/// applies the returned result.
public protocol DuelPairingMutator: Sendable {

    /// Creates the round's duel pairs and derives the bot snapshot to display
    /// for the hero.
    func generateNewRoundPairings(
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        roundNumber: Int,
        playerCombatantId: CombatantID?,
        previousDisplayedBotSnapshot: CombatantSnapshot?
    ) -> DuelPairingResult
}

/// Result of `DuelPairingMutator.generateNewRoundPairings`: the round's duel
/// pairs and the bot snapshot to display for the hero.
public struct DuelPairingResult: Sendable {
    public let battleRound: BattleRound
    public let displayedBotSnapshot: CombatantSnapshot?

    public init(battleRound: BattleRound, displayedBotSnapshot: CombatantSnapshot?) {
        self.battleRound = battleRound
        self.displayedBotSnapshot = displayedBotSnapshot
    }
}

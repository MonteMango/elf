//
//  DefaultDuelPairingMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Default `DuelPairingMutator`. Mirrors the rules formerly inlined on
/// `BattleFightViewModel.generateNewRoundPairings`.
public final class DefaultDuelPairingMutator: DuelPairingMutator {

    // MARK: - Initialization

    public init() {}

    // MARK: - DuelPairingMutator

    public func generateNewRoundPairings(
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        roundNumber: Int,
        playerCombatantId: CombatantID?,
        previousDisplayedBotSnapshot: CombatantSnapshot?
    ) -> DuelPairingResult {
        @Dependency(\.duelPairingService) var duelPairingService
        @Dependency(\.debugBattleLogger) var debugLogger

        let battleRound = duelPairingService.createRandomPairs(
            leftTeam: leftTeam,
            rightTeam: rightTeam,
            roundNumber: roundNumber
        )

        var displayedBotSnapshot = previousDisplayedBotSnapshot
        if let heroId = playerCombatantId,
           let heroPair = battleRound.duelPairs.first(where: { $0.leftCombatantId == heroId }),
           let bot = rightTeam.first(where: { $0.id == heroPair.rightCombatantId }) {
            displayedBotSnapshot = bot
        }

        debugLogger.logRoundState(
            roundNumber: roundNumber,
            leftTeam: leftTeam,
            rightTeam: rightTeam,
            playerCombatantId: playerCombatantId,
            battleRound: battleRound
        )

        return DuelPairingResult(battleRound: battleRound, displayedBotSnapshot: displayedBotSnapshot)
    }
}

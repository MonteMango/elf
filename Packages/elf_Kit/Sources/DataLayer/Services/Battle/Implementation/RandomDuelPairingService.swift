//
//  RandomDuelPairingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Implementation of DuelPairingService that creates random duel pairs.
public final class RandomDuelPairingService: DuelPairingService {

    public init() {}

    public func createRandomPairs(
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        roundNumber: Int
    ) -> BattleRound {
        // Filter alive combatants
        let aliveLeft = leftTeam.filter { $0.isAlive }
        let aliveRight = rightTeam.filter { $0.isAlive }

        // Shuffle both teams for random pairing
        var shuffledLeft = aliveLeft.shuffled()
        var shuffledRight = aliveRight.shuffled()

        // Create pairs until one team runs out
        var duelPairs: [DuelPair] = []
        let pairCount = min(shuffledLeft.count, shuffledRight.count)

        for index in 0..<pairCount {
            let pair = DuelPair(
                leftCombatantId: shuffledLeft[index].id,
                rightCombatantId: shuffledRight[index].id
            )
            duelPairs.append(pair)
        }

        // Determine waiting combatants
        let waitingLeftIds: [UUID]
        let waitingRightIds: [UUID]

        if shuffledLeft.count > pairCount {
            waitingLeftIds = shuffledLeft[pairCount...].map { $0.id }
            waitingRightIds = []
        } else if shuffledRight.count > pairCount {
            waitingLeftIds = []
            waitingRightIds = shuffledRight[pairCount...].map { $0.id }
        } else {
            waitingLeftIds = []
            waitingRightIds = []
        }

        return BattleRound(
            roundNumber: roundNumber,
            duelPairs: duelPairs,
            waitingLeftIds: waitingLeftIds,
            waitingRightIds: waitingRightIds
        )
    }
}

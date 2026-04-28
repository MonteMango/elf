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
        let aliveLeft = leftTeam.filter { $0.isAlive }
        let aliveRight = rightTeam.filter { $0.isAlive }

        let shuffledLeft = aliveLeft.shuffled()
        let shuffledRight = aliveRight.shuffled()
        let pairCount = min(shuffledLeft.count, shuffledRight.count)

        var duelPairs: [DuelPair] = []
        for index in 0..<pairCount {
            duelPairs.append(DuelPair(
                leftCombatantId: shuffledLeft[index].id,
                rightCombatantId: shuffledRight[index].id
            ))
        }

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

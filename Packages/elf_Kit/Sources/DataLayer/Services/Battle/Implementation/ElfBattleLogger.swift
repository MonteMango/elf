//
//  ElfBattleLogger.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public final class ElfBattleLogger: BattleLogger {

    public init() {}

    public func createRoundLog(
        roundNumber: Int,
        playerSnapshot: CombatantSnapshot,
        botSnapshot: CombatantSnapshot,
        playerActions: (attack: Set<BodyPart>, defense: Set<BodyPart>),
        botActions: (attack: Set<BodyPart>, defense: Set<BodyPart>),
        playerResults: [BodyPart: PointStatus],
        botResults: [BodyPart: PointStatus],
        playerOldHP: Int,
        botOldHP: Int
    ) -> ManualBattleRoundLog {
        return ManualBattleRoundLog(
            roundNumber: roundNumber,
            action: [
                playerSnapshot.id: BattleRoundAction(
                    attackPoints: Array(playerActions.attack),
                    defensePoints: Array(playerActions.defense)
                ),
                botSnapshot.id: BattleRoundAction(
                    attackPoints: Array(botActions.attack),
                    defensePoints: Array(botActions.defense)
                )
            ],
            duels: [(playerSnapshot.id, botSnapshot.id)],
            calculatedPreResults: [:], // MVP: empty for now
            results: [
                playerSnapshot.id: BattleRoundResult(
                    pointStatus: playerResults,
                    oldHP: playerOldHP
                ),
                botSnapshot.id: BattleRoundResult(
                    pointStatus: botResults,
                    oldHP: botOldHP
                )
            ]
        )
    }
}

// MARK: - Sendable Conformance
extension ElfBattleLogger: @unchecked Sendable {}

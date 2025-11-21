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
        playerHero: ElfHero,
        botHero: ElfHero,
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
                playerHero: BattleRoundAction(
                    attackPoints: Array(playerActions.attack),
                    defensePoints: Array(playerActions.defense)
                ),
                botHero: BattleRoundAction(
                    attackPoints: Array(botActions.attack),
                    defensePoints: Array(botActions.defense)
                )
            ],
            duels: [(playerHero, botHero)],
            calculatedPreResults: [:], // MVP: empty for now
            results: [
                playerHero: BattleRoundResult(
                    pointStatus: playerResults,
                    oldHP: playerOldHP
                ),
                botHero: BattleRoundResult(
                    pointStatus: botResults,
                    oldHP: botOldHP
                )
            ]
        )
    }
}

// MARK: - Sendable Conformance
extension ElfBattleLogger: @unchecked Sendable {}

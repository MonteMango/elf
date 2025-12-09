//
//  BattleLogger.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public protocol BattleLogger: Sendable {
    /// Create a round log entry from combat results
    /// - Parameters:
    ///   - roundNumber: Current round number
    ///   - playerSnapshot: Player's combatant snapshot
    ///   - botSnapshot: Bot's combatant snapshot
    ///   - playerActions: Player's selected attack and defense points
    ///   - botActions: Bot's selected attack and defense points
    ///   - playerResults: Combat results for player as defender
    ///   - botResults: Combat results for bot as defender
    ///   - playerOldHP: Player HP before damage
    ///   - botOldHP: Bot HP before damage
    /// - Returns: Round log entry
    func createRoundLog(
        roundNumber: Int,
        playerSnapshot: CombatantSnapshot,
        botSnapshot: CombatantSnapshot,
        playerActions: (attack: Set<BodyPart>, defense: Set<BodyPart>),
        botActions: (attack: Set<BodyPart>, defense: Set<BodyPart>),
        playerResults: [BodyPart: PointStatus],
        botResults: [BodyPart: PointStatus],
        playerOldHP: Int,
        botOldHP: Int
    ) -> ManualBattleRoundLog
}

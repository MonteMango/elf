//
//  BotBattleSummary.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Foundation

/// Lightweight record of one bot battle, kept for analytics only. The full
/// `BattleResult` (round-by-round history) is discarded after rewards are
/// computed — across 79 bots × 5 battles materializing it would be pure waste.
///
/// Currently surfaced through the debug logger at the end of the world turn.
public struct BotBattleSummary: Sendable, Equatable {
    public let monsterId: MonsterID
    public let monsterTitle: String
    public let won: Bool
    public let experienceGained: Int
    public let dropCount: Int

    public init(
        monsterId: MonsterID,
        monsterTitle: String,
        won: Bool,
        experienceGained: Int,
        dropCount: Int
    ) {
        self.monsterId = monsterId
        self.monsterTitle = monsterTitle
        self.won = won
        self.experienceGained = experienceGained
        self.dropCount = dropCount
    }
}

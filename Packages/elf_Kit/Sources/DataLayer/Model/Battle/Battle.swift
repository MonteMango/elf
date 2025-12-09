//
//  Battle.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.08.25.
//

import Foundation

public struct Battle: Sendable, Identifiable {
    public let id: UUID

    /// Left team combatants (player team). Uses CombatantSnapshot for unified elf/monster handling.
    public let leftTeam: [CombatantSnapshot]

    /// Right team combatants (opponent team). Uses CombatantSnapshot for unified elf/monster handling.
    public let rightTeam: [CombatantSnapshot]

    public var currentRound: Int {
        // based on roundLog.count + 1
        return roundLog.count + 1
    }

    // history of rounds
    public var roundLog: [ManualBattleRoundLog] = []

    public init(
        id: UUID = UUID(),
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot]
    ) {
        self.id = id
        self.leftTeam = leftTeam
        self.rightTeam = rightTeam
    }
}

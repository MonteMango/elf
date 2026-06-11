//
//  DuelPair.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Represents a duel pair between two combatants from opposing teams.
/// Each pair consists of one combatant from the left team and one from the right team.
public struct DuelPair: Sendable, Identifiable, Hashable {
    public let id: UUID

    /// ID of the combatant from the left team
    public let leftCombatantId: CombatantID

    /// ID of the combatant from the right team
    public let rightCombatantId: CombatantID

    public init(
        id: UUID = UUID(),
        leftCombatantId: CombatantID,
        rightCombatantId: CombatantID
    ) {
        self.id = id
        self.leftCombatantId = leftCombatantId
        self.rightCombatantId = rightCombatantId
    }
}

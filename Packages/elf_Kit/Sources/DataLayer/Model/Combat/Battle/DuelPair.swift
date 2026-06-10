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
    public let leftCombatantId: UUID

    /// ID of the combatant from the right team
    public let rightCombatantId: UUID

    public init(
        id: UUID = UUID(),
        leftCombatantId: UUID,
        rightCombatantId: UUID
    ) {
        self.id = id
        self.leftCombatantId = leftCombatantId
        self.rightCombatantId = rightCombatantId
    }
}

//
//  BotTurnResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Foundation

/// The aggregated outcome of one AI elf's world turn — the *delta* to apply
/// back to that elf. The simulator accumulates these across the bot's battles
/// off-main; `GameSession.applyWorldTurn` writes them onto
/// `houses[slot.houseIndex].members[slot.memberIndex]` on the main actor.
///
/// Because every result targets a distinct elf (`slot`), applying the whole
/// `WorldTurnOutcome` is conflict-free by construction — the player's slot is
/// never present.
public struct BotTurnResult: Sendable, Equatable {
    /// Which elf this delta belongs to.
    public let slot: RosterSlot

    /// Total experience earned across all of the bot's battles.
    public let experienceGained: Int

    /// Materials dropped (unstacked; the inventory service merges them on apply).
    public let materials: [MaterialReward]

    /// Weapons dropped across all battles.
    public let weapons: [ElfWeaponItem]

    /// Armor pieces dropped across all battles.
    public let armor: [ElfDefenseItem]

    /// Action points actually spent (e.g. 5 hunts × 20 = 100).
    public let actionPointsSpent: Int

    /// Per-battle records, for analytics/logging only.
    public let battles: [BotBattleSummary]

    public init(
        slot: RosterSlot,
        experienceGained: Int,
        materials: [MaterialReward],
        weapons: [ElfWeaponItem],
        armor: [ElfDefenseItem],
        actionPointsSpent: Int,
        battles: [BotBattleSummary]
    ) {
        self.slot = slot
        self.experienceGained = experienceGained
        self.materials = materials
        self.weapons = weapons
        self.armor = armor
        self.actionPointsSpent = actionPointsSpent
        self.battles = battles
    }
}

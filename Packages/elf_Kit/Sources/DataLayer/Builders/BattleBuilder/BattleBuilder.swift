//
//  BattleBuilder.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// One elf-side participant for a battle. Wraps the roster `ElfInfo` plus an
/// optional current HP/MP override carried over from a dungeon run; `nil`
/// reserves mean the participant enters the battle at full HP/MP (the snapshot's
/// buff-folded cap).
public struct BattlePartyMember: Sendable {

    public let elf: ElfInfo

    /// Current HP carried over from a dungeon run. `nil` → full reserves from the
    /// built snapshot. Clamped to the snapshot's `maxHP` by the builder.
    public let currentHP: Int?

    /// Current MP carried over from a dungeon run. `nil` → full reserves from the
    /// built snapshot. Clamped to the snapshot's `maxMP` by the builder.
    public let currentMP: Int?

    public init(elf: ElfInfo, currentHP: Int? = nil, currentMP: Int? = nil) {
        self.elf = elf
        self.currentHP = currentHP
        self.currentMP = currentMP
    }
}

/// Assembles a `Battle` from elf-side party members (left team) and monster
/// instances (right team). Centralizes the snapshot-building + equipment-map +
/// `Battle(...)` assembly that previously lived inline in every screen that
/// starts a fight (Hunt, Dungeon room, Farm encounter, Game Day 5v5).
///
/// Per-screen *policy* (spending action points, picking a random monster,
/// filtering downed members, expanding `MonsterRef.count`) stays at the call
/// site — the builder only consumes a resolved party and a resolved monster
/// list.
public protocol BattleBuilder: Sendable {

    /// Builds a `Battle` from `party` (left) versus `monsters` (right).
    ///
    /// Each member's level is computed internally from `elf.currentExp` via
    /// `ProgressionService`, and `elf.globalBuffs` are folded into the snapshot;
    /// monsters are built with empty buffs. Equipment is keyed by each elf's
    /// snapshot id. A member's `currentHP`/`currentMP` override (if set) is
    /// clamped to the snapshot's max and applied after construction.
    ///
    /// - Returns: The assembled `Battle`, or `nil` if either team is empty.
    func buildBattle(party: [BattlePartyMember], monsters: [Monster]) -> Battle?
}

//
//  CombatantSource.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// The roster entity a `CombatantSnapshot` was built from.
///
/// Replaces the former raw `sourceId: UUID` — that value was only ever a real
/// entity id for monsters (`monster.id`); elf combatants carried a throwaway
/// UUID. Modelling it as a sum makes "which kind of entity" explicit and lets
/// the monster id be recovered type-safely (e.g. reward calculation).
public enum CombatantSource: Sendable, Hashable {

    /// A roster `ElfInfo` (player or ally), identified by its `ElfID`.
    case elf(ElfID)

    /// A dev-only synthetic combatant (BattleSetup screen) with no roster entity.
    case synthetic

    /// A catalog `Monster`, identified by its `MonsterID`.
    case monster(MonsterID)
}

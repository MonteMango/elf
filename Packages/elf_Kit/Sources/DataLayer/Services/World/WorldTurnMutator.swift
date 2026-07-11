//
//  WorldTurnMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Pure rule family for applying a whole world turn's results to the roster,
/// extracted from `GameSession`'s World Turn logic (T12): for each bot, awards
/// experience, adds drops, and spends the action points it used. `GameSession`
/// stays the single *owner* of state — it snapshots the current houses,
/// delegates to this stateless mutator, and writes the returned houses back.
public protocol WorldTurnMutator: Sendable {

    /// Applies every result in `outcome` to `houses`, returning the updated
    /// snapshot. Every result targets a distinct elf slot (the player is
    /// never among them), so the writes are conflict-free. Each is verified
    /// against the elf's `id` before applying, guarding against any roster
    /// reshuffle between snapshot and apply — a result whose `slot.id` no
    /// longer matches the elf occupying that slot is skipped entirely.
    func applyWorldTurn(_ outcome: WorldTurnOutcome, to houses: [House]) -> [House]
}

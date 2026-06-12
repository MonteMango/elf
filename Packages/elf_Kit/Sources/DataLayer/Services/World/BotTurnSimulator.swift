//
//  BotTurnSimulator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Foundation

/// Executes one AI elf's `BotTurnPlan` — runs its battles and aggregates the
/// outcome into a `BotTurnResult` delta. Pure and `Sendable`: it reads only the
/// value-type `elf` it is given and never touches game state, so many instances
/// run concurrently in `WorldTurnRunner`'s task group.
///
/// Determinism: all randomness (monster choice + combat) is driven by a
/// per-battle generator derived from the `seed`, so the same `(plan, elf, seed)`
/// always yields the same result.
public protocol BotTurnSimulator: Sendable {

    /// Simulate the plan for one elf.
    /// - Parameters:
    ///   - plan: The ordered actions to execute (carries the elf's `slot`).
    ///   - elf: A value-type copy of the elf's state, used to build combat
    ///     snapshots and pick a level-appropriate monster pool.
    ///   - seed: Root seed for this elf's turn; per-battle seeds derive from it.
    /// - Returns: The aggregated delta to apply back to the elf.
    func simulate(_ plan: BotTurnPlan, elf: ElfInfo, seed: UInt64) async -> BotTurnResult
}

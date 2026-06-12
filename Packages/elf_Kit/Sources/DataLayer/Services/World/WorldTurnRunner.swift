//
//  WorldTurnRunner.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Foundation

/// Orchestrates a whole world turn: plans and simulates every AI elf, then
/// returns the combined `WorldTurnOutcome` for the caller to apply.
///
/// **Off-main by design.** This is a plain `Sendable` service — *not*
/// `@MainActor`. Its `run` method is `nonisolated async`, so the business logic
/// (planning, 79 × 5 battles) executes on the cooperative thread pool. The
/// caller (`GameDayStateViewModel`) builds the value-type `[BotTurnContext]` on
/// the main actor, awaits `run` off-main, and applies the result back on main —
/// the simulation never touches the observable `GameStore`.
public protocol WorldTurnRunner: Sendable {

    /// Plan and simulate every bot concurrently.
    /// - Parameters:
    ///   - bots: Value-type snapshots of each AI elf to simulate (excludes the
    ///     player). Order is preserved in the returned results.
    ///   - turnSeed: Root seed for the turn; each bot derives an independent
    ///     per-bot seed from it, making the whole turn reproducible.
    /// - Returns: The combined outcome — one `BotTurnResult` per input bot.
    func run(bots: [BotTurnContext], turnSeed: UInt64) async -> WorldTurnOutcome
}

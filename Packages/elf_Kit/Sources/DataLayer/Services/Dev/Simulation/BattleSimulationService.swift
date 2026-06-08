//
//  BattleSimulationService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Dependencies

/// Service for simulating battles between bots
///
/// Runs the battle loop, calculates combat results, and collects statistics.
/// Used by AutoBattleViewModel and MultiBattleViewModel.
public protocol BattleSimulationService: Sendable {

    /// Run a single battle simulation and return the result.
    ///
    /// `async` because the per-round mechanics run on the cooperative pool
    /// via `BattleRoundRunner`. Callers (`MultiBattleViewModel`) already
    /// invoke this from an async context.
    ///
    /// - Parameters:
    ///   - battle: The battle configuration with both teams.
    ///   - generator: Per-battle random source. Sweeps pass a distinct seeded
    ///     generator per battle for contention-free, reproducible runs.
    /// - Returns: Complete battle result including winner, rounds, and statistics.
    func runSingleBattle(_ battle: Battle, using generator: WithRandomNumberGenerator) async -> BattleResult
}

public extension BattleSimulationService {
    /// Convenience: resolves `\.withRandomNumberGenerator` once and delegates.
    func runSingleBattle(_ battle: Battle) async -> BattleResult {
        @Dependency(\.withRandomNumberGenerator) var generator
        return await runSingleBattle(battle, using: generator)
    }
}

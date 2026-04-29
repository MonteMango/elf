//
//  BattleRoundRunner.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Runs a single battle round across all duel pairs of a `BattleRound`,
/// returning new team snapshots and per-pair detail.
///
/// The runner is the single source of truth for "one round" mechanics:
/// `BattleFightViewModel` (manual hero flow), `AutoBattleViewModel` and
/// `ElfBattleSimulationService` (1v1 dev/simulation flows) all delegate to
/// it. 1v1 callers wrap their two combatants in a synthetic
/// `BattleRound([DuelPair(left, right)])` before calling.
public protocol BattleRoundRunner: Sendable {
    /// Runs every pair concurrently on the cooperative pool, applies HP
    /// changes to copies of the input teams, and returns the new state.
    ///
    /// - Parameters:
    ///   - leftTeam: combatants of the left team. Not mutated.
    ///   - rightTeam: combatants of the right team. Not mutated.
    ///   - round: the duel pairs to run this turn.
    ///   - heroSelection: the player's attack/defense choice. If non-nil and
    ///     the hero (`heroSelection.combatantId`) is paired in `round`, that
    ///     pair uses the supplied selection; every other pair uses bot AI.
    ///     Pass `nil` for fully-auto rounds.
    func runRound(
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        round: BattleRound,
        heroSelection: HeroSelection?
    ) async -> RoundOutcome
}

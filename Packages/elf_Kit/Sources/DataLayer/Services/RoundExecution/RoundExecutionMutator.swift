//
//  RoundExecutionMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Rule family for running a single battle round and settling its outcome,
/// extracted from `BattleFightViewModel` (T15): the `executeFightRound`
/// readiness guard, `runRound`'s round-advance-vs-battle-ended bookkeeping
/// (shared by `executeFightRound` and `executeWatchUntilEnd`), and the
/// `determineBattleOutcome` defensive-fallback wrapper. `BattleFightViewModel`
/// stays the owner of round/UI state — it delegates to this mutator and
/// applies the returned result.
public protocol RoundExecutionMutator: Sendable {

    /// Whether the hero has made a full attack/defense selection when paired
    /// this round (unpaired hero always ready — bot pairs never wait on it).
    func canExecuteFightRound(
        heroIsPaired: Bool,
        playerAttackPoints: Set<BodyPart>,
        requiredAttackPoints: Int,
        playerDefensePoints: Set<BodyPart>,
        requiredDefensePoints: Int
    ) -> Bool

    /// Runs one round via `BattleRoundRunner` and applies the round-advance
    /// (or battle-ended) bookkeeping to the returned result.
    func runRound(
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        round: BattleRound,
        heroSelection: HeroSelection?,
        currentRoundNumber: Int
    ) async -> RoundExecutionResult

    /// Settles the final `BattleOutcome` once the battle has ended, with a
    /// defensive `.draw` fallback.
    func determineBattleOutcome(
        left: [CombatantSnapshot],
        right: [CombatantSnapshot]
    ) -> BattleOutcome
}

/// Result of `RoundExecutionMutator.runRound`: the updated teams, per-pair
/// detail, and the round-advance-vs-battle-ended bookkeeping.
public struct RoundExecutionResult: Sendable {
    public let updatedLeftTeam: [CombatantSnapshot]
    public let updatedRightTeam: [CombatantSnapshot]
    public let pairResults: [PairResult]
    public let battleEnded: Bool
    public let nextRoundNumber: Int

    public init(
        updatedLeftTeam: [CombatantSnapshot],
        updatedRightTeam: [CombatantSnapshot],
        pairResults: [PairResult],
        battleEnded: Bool,
        nextRoundNumber: Int
    ) {
        self.updatedLeftTeam = updatedLeftTeam
        self.updatedRightTeam = updatedRightTeam
        self.pairResults = pairResults
        self.battleEnded = battleEnded
        self.nextRoundNumber = nextRoundNumber
    }
}

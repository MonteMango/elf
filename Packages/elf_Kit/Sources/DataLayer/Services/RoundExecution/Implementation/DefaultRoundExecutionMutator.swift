//
//  DefaultRoundExecutionMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Default `RoundExecutionMutator`. Mirrors the rules formerly inlined on
/// `BattleFightViewModel`. `battleRoundRunner` is resolved lazily inside
/// `runRound` (not at init) so constructing this mutator doesn't eagerly pull
/// its live-only dependency — the same convention `DefaultRoomBattleRewardMutator`
/// follows.
public final class DefaultRoundExecutionMutator: RoundExecutionMutator {

    // MARK: - Initialization

    public init() {}

    // MARK: - RoundExecutionMutator

    public func canExecuteFightRound(
        heroIsPaired: Bool,
        playerAttackPoints: Set<BodyPart>,
        requiredAttackPoints: Int,
        playerDefensePoints: Set<BodyPart>,
        requiredDefensePoints: Int
    ) -> Bool {
        guard heroIsPaired else { return true }
        return playerAttackPoints.count == requiredAttackPoints
            && playerDefensePoints.count == requiredDefensePoints
    }

    public func runRound(
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        round: BattleRound,
        heroSelection: HeroSelection?,
        currentRoundNumber: Int
    ) async -> RoundExecutionResult {
        @Dependency(\.battleRoundRunner) var battleRoundRunner

        let outcome = await battleRoundRunner.runRound(
            leftTeam: leftTeam,
            rightTeam: rightTeam,
            round: round,
            heroSelection: heroSelection
        )

        let battleEnded = outcome.battleOutcome != nil
        return RoundExecutionResult(
            updatedLeftTeam: outcome.updatedLeftTeam,
            updatedRightTeam: outcome.updatedRightTeam,
            pairResults: outcome.pairResults,
            battleEnded: battleEnded,
            nextRoundNumber: battleEnded ? currentRoundNumber : currentRoundNumber + 1
        )
    }

    public func determineBattleOutcome(
        left: [CombatantSnapshot],
        right: [CombatantSnapshot]
    ) -> BattleOutcome {
        // `?? .draw` is a defensive fallback — callers only settle the final
        // outcome once at least one side has wiped.
        detectBattleOutcome(left: left, right: right) ?? .draw
    }
}

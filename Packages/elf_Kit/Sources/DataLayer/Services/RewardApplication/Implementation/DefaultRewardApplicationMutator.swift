//
//  DefaultRewardApplicationMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Default `RewardApplicationMutator`. Mirrors the rule formerly inlined on
/// `GameSession.concludeHuntBattle`. Collaborators are resolved lazily inside
/// `concludeHuntBattle` (not at init) so simply constructing this mutator
/// doesn't eagerly pull its live-only deps — the same rule the original
/// inline code followed.
public final class DefaultRewardApplicationMutator: RewardApplicationMutator {

    // MARK: - Initialization

    public init() {}

    // MARK: - RewardApplicationMutator

    public func concludeHuntBattle(
        battle: Battle,
        outcome: BattleOutcome,
        playerCurrentExp: Int
    ) -> RewardApplicationResult {
        @Dependency(\.battleResultCalculator) var battleResultCalculator
        @Dependency(\.monsterRepository) var monsterRepository

        let monster = battle.botMonsterID.flatMap { monsterRepository.getById(id: $0) }

        // Order matters: compute the result against the pre-mutation exp
        // passed in by the caller, so the overlay's previous→new XP
        // progression is correct. Do not reorder.
        let result = battleResultCalculator.calculateResult(
            outcome: outcome,
            monster: monster,
            currentExp: playerCurrentExp
        )
        return RewardApplicationResult(
            manualBattleResult: result,
            experienceToAdd: result.experienceGained,
            huntRewardsToAdd: result.huntRewards
        )
    }
}

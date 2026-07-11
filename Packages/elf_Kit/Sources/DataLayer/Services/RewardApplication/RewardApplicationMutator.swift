//
//  RewardApplicationMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Rule family for computing a hunt battle's reward result, extracted from
/// `GameSession` (T7): `concludeHuntBattle`'s reward-computation logic.
/// `GameSession` stays the single *owner* of player state — it snapshots the
/// current exp, delegates to this mutator, and applies the returned
/// mutations (exp/inventory) itself.
public protocol RewardApplicationMutator: Sendable {

    /// Computes a hunt battle's result against the given pre-mutation exp,
    /// and reports what the caller should apply (experience, hunt rewards).
    /// Does not mutate any state itself — pure computation only.
    func concludeHuntBattle(
        battle: Battle,
        outcome: BattleOutcome,
        playerCurrentExp: Int
    ) -> RewardApplicationResult
}

/// Result of `concludeHuntBattle`: the overlay result plus the mutations the
/// caller should apply.
public struct RewardApplicationResult: Sendable, Equatable {
    public let manualBattleResult: ManualBattleResult
    public let experienceToAdd: Int
    public let huntRewardsToAdd: HuntRewards?

    public init(
        manualBattleResult: ManualBattleResult,
        experienceToAdd: Int,
        huntRewardsToAdd: HuntRewards?
    ) {
        self.manualBattleResult = manualBattleResult
        self.experienceToAdd = experienceToAdd
        self.huntRewardsToAdd = huntRewardsToAdd
    }
}

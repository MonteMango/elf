//
//  RewardApplicationMutatorTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests the `RewardApplicationMutator` extracted from `GameSession`'s
/// Battle-conclusion rule family (T7): `concludeHuntBattle`'s reward-computation
/// logic. Exercised directly against the injected type (via
/// `@Dependency(\.rewardApplicationMutator)`), independent of `GameSession`.
///
/// AC-04 invariant #1 (named regression): the reward result must be computed
/// against the player's exp *before* any exp/inventory mutation runs. This
/// mutator is pure — it never mutates `GameSession` state itself, it only
/// reports what should be applied — so the invariant here is: the
/// `currentExp` value the mutator hands to `battleResultCalculator` is exactly
/// the pre-battle value the caller passed in, never one already bumped by a
/// prior reward.
final class RewardApplicationMutatorTests: XCTestCase {

    // MARK: - Fakes

    /// Spy calculator recording the `currentExp` it was called with, so tests
    /// can assert the mutator never mutates state before this call — it must
    /// always be the exact pre-mutation value the caller supplied.
    private final class SpyBattleResultCalculator: BattleResultCalculator, @unchecked Sendable {
        private(set) var receivedCurrentExp: [Int] = []
        let resultToReturn: ManualBattleResult

        init(resultToReturn: ManualBattleResult) {
            self.resultToReturn = resultToReturn
        }

        func calculateResult(outcome: BattleOutcome, monster: Monster?, currentExp: Int) -> ManualBattleResult {
            receivedCurrentExp.append(currentExp)
            return resultToReturn
        }
    }

    private func makeBattle() -> Battle {
        // Empty rightTeam ⇒ `botMonsterID == nil`, so the mutator's monster
        // lookup short-circuits and `monsterRepository` is never resolved —
        // keeps this test independent of the (fatalError-liveValue,
        // no-testValue) monster repository dependency.
        Battle(leftTeam: [], rightTeam: [])
    }

    private func makeResult(experienceGained: Int, huntRewards: HuntRewards?) -> ManualBattleResult {
        ManualBattleResult(
            outcome: .victory,
            experienceGained: experienceGained,
            drops: [],
            huntRewards: huntRewards,
            previousLevel: 1, previousExp: 0, previousExpToNext: 100,
            newLevel: 1, newExp: experienceGained, newExpToNext: 100
        )
    }

    // MARK: - AC-04 invariant #1 (named regression)

    /// Named regression test for AC-04 invariant #1: `concludeHuntBattle`
    /// computes the reward result against the pre-mutation exp value — the
    /// exact `playerCurrentExp` the caller passed in, not a value already
    /// bumped by this call. Fails if a future change reorders things so the
    /// mutator (incorrectly) applies a mutation before computing the result.
    func testConcludeHuntBattle_AC04Invariant1_ComputesResultAgainstPreMutationExp() {
        let spy = SpyBattleResultCalculator(resultToReturn: makeResult(experienceGained: 50, huntRewards: nil))
        let preMutationExp = 120

        _ = withDependencies {
            $0.battleResultCalculator = spy
        } operation: {
            @Dependency(\.rewardApplicationMutator) var mutator
            return mutator.concludeHuntBattle(
                battle: makeBattle(),
                outcome: .victory,
                playerCurrentExp: preMutationExp
            )
        }

        XCTAssertEqual(spy.receivedCurrentExp, [preMutationExp])
    }

    // MARK: - Reports mutations to apply, does not apply them itself

    func testConcludeHuntBattle_VictoryWithExperience_ReportsExperienceToAdd() {
        let spy = SpyBattleResultCalculator(resultToReturn: makeResult(experienceGained: 42, huntRewards: nil))

        let result = withDependencies {
            $0.battleResultCalculator = spy
        } operation: {
            @Dependency(\.rewardApplicationMutator) var mutator
            return mutator.concludeHuntBattle(battle: makeBattle(), outcome: .victory, playerCurrentExp: 0)
        }

        XCTAssertEqual(result.experienceToAdd, 42)
        XCTAssertEqual(result.manualBattleResult.experienceGained, 42)
    }

    func testConcludeHuntBattle_NoExperienceGained_ReportsNoExperienceToAdd() {
        let spy = SpyBattleResultCalculator(resultToReturn: makeResult(experienceGained: 0, huntRewards: nil))

        let result = withDependencies {
            $0.battleResultCalculator = spy
        } operation: {
            @Dependency(\.rewardApplicationMutator) var mutator
            return mutator.concludeHuntBattle(battle: makeBattle(), outcome: .defeat, playerCurrentExp: 0)
        }

        XCTAssertEqual(result.experienceToAdd, 0)
    }

    func testConcludeHuntBattle_WithHuntRewards_ReportsHuntRewardsToAdd() {
        let huntRewards = HuntRewards(experience: 10, materials: [])
        let spy = SpyBattleResultCalculator(resultToReturn: makeResult(experienceGained: 10, huntRewards: huntRewards))

        let result = withDependencies {
            $0.battleResultCalculator = spy
        } operation: {
            @Dependency(\.rewardApplicationMutator) var mutator
            return mutator.concludeHuntBattle(battle: makeBattle(), outcome: .victory, playerCurrentExp: 0)
        }

        XCTAssertEqual(result.huntRewardsToAdd, huntRewards)
    }

    func testConcludeHuntBattle_NoHuntRewards_ReportsNilHuntRewardsToAdd() {
        let spy = SpyBattleResultCalculator(resultToReturn: makeResult(experienceGained: 0, huntRewards: nil))

        let result = withDependencies {
            $0.battleResultCalculator = spy
        } operation: {
            @Dependency(\.rewardApplicationMutator) var mutator
            return mutator.concludeHuntBattle(battle: makeBattle(), outcome: .defeat, playerCurrentExp: 0)
        }

        XCTAssertNil(result.huntRewardsToAdd)
    }
}

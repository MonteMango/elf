//
//  DefaultBattleResultCalculatorTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for `DefaultBattleResultCalculator` — the post-battle rewards/XP
/// calculator. Verifies the victory/defeat/no-monster branches and that XP
/// level state is computed before and after the gained experience.
final class DefaultBattleResultCalculatorTests: XCTestCase {

    // MARK: - Mocks

    final class MockHuntService: HuntService, @unchecked Sendable {
        nonisolated(unsafe) var rewards = HuntRewards(experience: 50, materials: [], weapon: nil, armor: nil)
        nonisolated(unsafe) var calculateRewardsCallCount = 0
        func calculateRewards(for monster: Monster) -> HuntRewards {
            calculateRewardsCallCount += 1
            return rewards
        }
    }

    final class MockDropService: DropService, @unchecked Sendable {
        nonisolated(unsafe) var lastDidWin: Bool?
        nonisolated(unsafe) var callCount = 0
        func convertToDropItems(rewards: HuntRewards, didWin: Bool) -> [DropItem] {
            callCount += 1
            lastDidWin = didWin
            return []
        }
    }

    /// `calculateLevel` = exp / 100 (so 150 → L1, 250 → L2); `expToNextLevel`
    /// fixed at 100. Other protocol methods are unused stubs.
    final class MockProgressionService: ProgressionService, @unchecked Sendable {
        func calculateLevel(currentExp: Int) -> Int { currentExp / 100 }
        func expToNextLevel(currentExp: Int) -> Int { 100 }
        func expProgress(currentExp: Int) -> Double { 0 }
        func farmingLevel(exp: Int) -> Int { 0 }
        func farmingProgress(exp: Int) -> Double { 0 }
    }

    private func makeMonster() -> Monster {
        Monster(
            id: MonsterID(),
            title: "Test Monster",
            imageName: "",
            expReward: [ChanceAmount(amount: 50, chance: 1.0)],
            rightAttack: AttackProfile(minimumAttack: 1, maximumAttack: 3, epBlockCost: 100),
            leftAttack: nil,
            defensePoints: 2,
            hitPoints: 40,
            manaPoints: 0,
            strength: 5, agility: 5, power: 5, instinct: 5, endurance: 5,
            partsProtection: PartsProtection(head: 0, left: 0, center: 0, right: 0, legs: 0),
            drops: MonsterDrops(weapons: [], armor: [], materials: [])
        )
    }

    private func makeCalculator(
        hunt: MockHuntService, drop: MockDropService, progression: MockProgressionService
    ) -> DefaultBattleResultCalculator {
        withDependencies {
            $0.huntService = hunt
            $0.dropService = drop
            $0.progressionService = progression
        } operation: {
            DefaultBattleResultCalculator()
        }
    }

    // MARK: - Tests

    func testVictoryWithMonster_GrantsExperienceAndDrops() {
        let hunt = MockHuntService()
        let drop = MockDropService()
        let result = makeCalculator(hunt: hunt, drop: drop, progression: MockProgressionService())
            .calculateResult(outcome: .victory, monster: makeMonster(), currentExp: 150)

        XCTAssertEqual(result.experienceGained, 50, "victory grants the hunt reward's experience")
        XCTAssertNotNil(result.huntRewards)
        XCTAssertEqual(hunt.calculateRewardsCallCount, 1)
        XCTAssertEqual(drop.callCount, 1)
        XCTAssertEqual(drop.lastDidWin, true)
        XCTAssertEqual(result.newExp, 200, "150 + 50 gained")
        XCTAssertEqual(result.previousLevel, 1, "150/100")
        XCTAssertEqual(result.newLevel, 2, "200/100 — leveled up")
    }

    func testDefeatWithMonster_NoRewards() {
        let hunt = MockHuntService()
        let drop = MockDropService()
        let result = makeCalculator(hunt: hunt, drop: drop, progression: MockProgressionService())
            .calculateResult(outcome: .defeat, monster: makeMonster(), currentExp: 150)

        XCTAssertEqual(result.experienceGained, 0, "defeat grants no experience")
        XCTAssertNil(result.huntRewards)
        XCTAssertTrue(result.drops.isEmpty)
        XCTAssertEqual(hunt.calculateRewardsCallCount, 0, "rewards not computed on a loss")
        XCTAssertEqual(drop.callCount, 0)
        XCTAssertEqual(result.newExp, 150, "no XP change")
        XCTAssertEqual(result.previousLevel, result.newLevel)
    }

    func testNoMonster_NoRewards() {
        let hunt = MockHuntService()
        let drop = MockDropService()
        let result = makeCalculator(hunt: hunt, drop: drop, progression: MockProgressionService())
            .calculateResult(outcome: .victory, monster: nil, currentExp: 250)

        XCTAssertEqual(result.experienceGained, 0, "no monster → no rewards even on victory")
        XCTAssertNil(result.huntRewards)
        XCTAssertEqual(hunt.calculateRewardsCallCount, 0)
        XCTAssertEqual(result.newExp, 250)
        XCTAssertEqual(result.outcome, .victory)
    }
}

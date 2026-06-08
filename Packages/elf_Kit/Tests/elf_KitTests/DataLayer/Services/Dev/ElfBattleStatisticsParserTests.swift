//
//  ElfBattleStatisticsParserTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import XCTest
@testable import elf_Kit

/// Tests for `ElfBattleStatisticsParser` and the `BattleStatisticsAccumulator`
/// it fills. After the dodge-first refactor, every non-`.nothing` body part
/// triggers exactly one dodge attempt and one crit attempt — these tests pin
/// that invariant alongside the per-status field-by-field aggregation.
final class ElfBattleStatisticsParserTests: XCTestCase {

    private let parser = ElfBattleStatisticsParser()

    // MARK: - Empty round

    func testEmptyRound_NoCountersTouched() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()

        parser.parseStatistics(
            attackingPoints: [],
            defendingPoints: [],
            results: [:],
            attackerStats: &attacker,
            defenderStats: &defender
        )

        XCTAssertEqual(attacker.critAttempts, 0)
        XCTAssertEqual(defender.dodgeAttempts, 0)
    }

    // MARK: - Hoisted counters (one per non-nothing attacked body part)

    func testNonNothingResults_IncrementCritAndDodgeAttempts() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()
        let results: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 5, strengthDamage: 2, enduranceReduction: 0, defenderArmor: 0),
            .body: .dodged(wasCrit: false),
            .legs: .blocked(epSpent: 100)
        ]

        parser.parseStatistics(
            attackingPoints: [.head, .body, .legs],
            defendingPoints: [.legs],
            results: results,
            attackerStats: &attacker,
            defenderStats: &defender
        )

        XCTAssertEqual(attacker.critAttempts, 3, "Every non-.nothing landed-or-cancelled attack counts as one crit attempt")
        XCTAssertEqual(defender.dodgeAttempts, 3, "Every non-.nothing landed-or-cancelled attack counts as one dodge attempt")
    }

    func testNothingResults_DoNotCount() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()
        let results: [BodyPart: PointStatus] = [
            .head: .nothing,
            .body: .nothing
        ]

        parser.parseStatistics(
            attackingPoints: [.head, .body],
            defendingPoints: [],
            results: results,
            attackerStats: &attacker,
            defenderStats: &defender
        )

        XCTAssertEqual(attacker.critAttempts, 0)
        XCTAssertEqual(defender.dodgeAttempts, 0)
    }

    func testMissingStatusInResults_Skipped() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()

        parser.parseStatistics(
            attackingPoints: [.head, .body],
            defendingPoints: [],
            results: [:], // empty — should not crash, no counters touched
            attackerStats: &attacker,
            defenderStats: &defender
        )

        XCTAssertEqual(attacker.critAttempts, 0)
        XCTAssertEqual(defender.dodgeAttempts, 0)
    }

    // MARK: - critHit

    func testCritHit_OnUndefended_CountsAsCritSuccess_NoBlockBreak() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()
        let results: [BodyPart: PointStatus] = [
            .head: .critHit(weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0,
                            defenderArmor: 0, multiplier: 2.0, epSpent: 0)
        ]

        parser.parseStatistics(
            attackingPoints: [.head],
            defendingPoints: [],
            results: results,
            attackerStats: &attacker,
            defenderStats: &defender
        )

        XCTAssertEqual(attacker.critSuccesses, 1)
        XCTAssertEqual(attacker.critMultipliers[2.0], 1)
        XCTAssertEqual(attacker.strengthDamage, 5)
        XCTAssertEqual(attacker.critBlockBreaks, 0, "Undefended crit must not increment block-break")
    }

    func testCritHit_OnDefended_IncrementsBlockBreak() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()
        let results: [BodyPart: PointStatus] = [
            .head: .critHit(weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0,
                            defenderArmor: 0, multiplier: 2.0, epSpent: 400)
        ]

        parser.parseStatistics(
            attackingPoints: [.head],
            defendingPoints: [.head],
            results: results,
            attackerStats: &attacker,
            defenderStats: &defender
        )

        XCTAssertEqual(attacker.critSuccesses, 1)
        XCTAssertEqual(attacker.critBlockBreaks, 1, "Defended crit must increment block-break")
    }

    // MARK: - hit

    func testHit_AccumulatesStrengthDamage() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()
        let results: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 10, strengthDamage: 7, enduranceReduction: 0, defenderArmor: 0),
            .body: .hit(weaponDamage: 8, strengthDamage: 3, enduranceReduction: 0, defenderArmor: 0)
        ]

        parser.parseStatistics(
            attackingPoints: [.head, .body],
            defendingPoints: [],
            results: results,
            attackerStats: &attacker,
            defenderStats: &defender
        )

        XCTAssertEqual(attacker.strengthDamage, 10)
        XCTAssertEqual(attacker.critSuccesses, 0)
    }

    // MARK: - blocked

    func testBlocked_NoCrit_OnlyAttemptsIncrement() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()
        let results: [BodyPart: PointStatus] = [
            .head: .blocked(epSpent: 200)
        ]

        parser.parseStatistics(
            attackingPoints: [.head],
            defendingPoints: [.head],
            results: results,
            attackerStats: &attacker,
            defenderStats: &defender
        )

        XCTAssertEqual(attacker.critAttempts, 1)
        XCTAssertEqual(attacker.critSuccesses, 0)
        XCTAssertEqual(attacker.strengthDamage, 0)
    }

    // MARK: - dodged

    func testDodged_NoCrit_IncrementsDodgeSuccessOnly() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()
        let results: [BodyPart: PointStatus] = [.body: .dodged(wasCrit: false)]

        parser.parseStatistics(
            attackingPoints: [.body],
            defendingPoints: [],
            results: results,
            attackerStats: &attacker,
            defenderStats: &defender
        )

        XCTAssertEqual(defender.dodgeSuccesses, 1)
        XCTAssertEqual(attacker.critSuccesses, 0)
        XCTAssertEqual(attacker.critsDodged, 0)
    }

    func testDodged_WithCrit_IncrementsCritSuccessAndCritsDodged() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()
        let results: [BodyPart: PointStatus] = [.body: .dodged(wasCrit: true)]

        parser.parseStatistics(
            attackingPoints: [.body],
            defendingPoints: [],
            results: results,
            attackerStats: &attacker,
            defenderStats: &defender
        )

        XCTAssertEqual(defender.dodgeSuccesses, 1)
        XCTAssertEqual(attacker.critSuccesses, 1)
        XCTAssertEqual(attacker.critsDodged, 1)
    }

    // MARK: - weakBlocked

    func testWeakBlocked_NoCrit_AccumulatesStrengthOnly() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()
        let results: [BodyPart: PointStatus] = [
            .head: .weakBlocked(weaponDamage: 10, strengthDamage: 6, enduranceReduction: 0,
                                defenderArmor: 4, multiplier: 1.0, finalDamage: 7, wasCrit: false)
        ]

        parser.parseStatistics(
            attackingPoints: [.head],
            defendingPoints: [.head],
            results: results,
            attackerStats: &attacker,
            defenderStats: &defender
        )

        XCTAssertEqual(attacker.strengthDamage, 6)
        XCTAssertEqual(attacker.critSuccesses, 0)
        XCTAssertEqual(attacker.critBlockBreaks, 0)
        XCTAssertNil(attacker.critMultipliers[1.0])
    }

    func testWeakBlocked_WithCrit_AlsoIncrementsCritCounters() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()
        let results: [BodyPart: PointStatus] = [
            .head: .weakBlocked(weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0,
                                defenderArmor: 2, multiplier: 2.0, finalDamage: 23, wasCrit: true)
        ]

        parser.parseStatistics(
            attackingPoints: [.head],
            defendingPoints: [.head],
            results: results,
            attackerStats: &attacker,
            defenderStats: &defender
        )

        XCTAssertEqual(attacker.strengthDamage, 5)
        XCTAssertEqual(attacker.critSuccesses, 1)
        XCTAssertEqual(attacker.critMultipliers[2.0], 1)
        XCTAssertEqual(attacker.critBlockBreaks, 1, "Weak-block crit must count as a crit block-break")
    }

    // MARK: - Mixed round (integration)

    /// Realistic mixed round: two strikes — one normal hit, one dodged crit
    /// (defender successfully dodges); plus one defended crit-block break.
    /// Verifies every counter lands on the right side at the right value.
    func testMixedRound_FullAggregation() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()

        let results: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 5, strengthDamage: 4, enduranceReduction: 0, defenderArmor: 0),
            .body: .dodged(wasCrit: true),
            .legs: .critHit(weaponDamage: 8, strengthDamage: 3, enduranceReduction: 0,
                            defenderArmor: 0, multiplier: 1.5, epSpent: 300)
        ]

        parser.parseStatistics(
            attackingPoints: [.head, .body, .legs],
            defendingPoints: [.legs],
            results: results,
            attackerStats: &attacker,
            defenderStats: &defender
        )

        // Hoisted counters.
        XCTAssertEqual(attacker.critAttempts, 3)
        XCTAssertEqual(defender.dodgeAttempts, 3)
        // Crit successes: dodged-crit + landed-crit.
        XCTAssertEqual(attacker.critSuccesses, 2)
        XCTAssertEqual(attacker.critsDodged, 1)
        // Block-break only from the defended landed crit.
        XCTAssertEqual(attacker.critBlockBreaks, 1)
        // Strength damage: hit (4) + crit (3) — dodge contributes nothing.
        XCTAssertEqual(attacker.strengthDamage, 7)
        // Multiplier histogram.
        XCTAssertEqual(attacker.critMultipliers[1.5], 1)
        // Defensive counters.
        XCTAssertEqual(defender.dodgeSuccesses, 1)
    }

    // MARK: - Accumulator reuse

    /// The accumulator is incremental — two parses on the same instance
    /// must sum, not overwrite.
    func testIncrementalAccumulation_AcrossMultipleRounds() {
        var attacker = BattleStatisticsAccumulator()
        var defender = BattleStatisticsAccumulator()

        let round1: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 5, strengthDamage: 4, enduranceReduction: 0, defenderArmor: 0)
        ]
        let round2: [BodyPart: PointStatus] = [
            .body: .hit(weaponDamage: 5, strengthDamage: 6, enduranceReduction: 0, defenderArmor: 0)
        ]

        parser.parseStatistics(
            attackingPoints: [.head], defendingPoints: [],
            results: round1,
            attackerStats: &attacker, defenderStats: &defender
        )
        parser.parseStatistics(
            attackingPoints: [.body], defendingPoints: [],
            results: round2,
            attackerStats: &attacker, defenderStats: &defender
        )

        XCTAssertEqual(attacker.critAttempts, 2)
        XCTAssertEqual(attacker.strengthDamage, 10)
        XCTAssertEqual(defender.dodgeAttempts, 2)
    }
}

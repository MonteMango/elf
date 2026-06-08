//
//  ElfChanceRollServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for `ElfChanceRollService.resolve(chance:)` used by Dodge and Crit
/// services. Pins the auto-fail / auto-success / normal-roll boundaries —
/// corner cases that matter for both services. Runs on a seeded generator,
/// so the statistical assertions are deterministic.
final class ElfChanceRollServiceTests: XCTestCase {

    override func invokeTest() {
        withDependencies {
            $0.withRandomNumberGenerator = WithRandomNumberGenerator(
                SeededRandomNumberGenerator(seed: 0xE1F)
            )
        } operation: {
            super.invokeTest()
        }
    }

    private func makeService() -> ElfChanceRollService {
        ElfChanceRollService()
    }

    func testNegativeChance_AutoFailsAndDoesNotRoll() {
        let service = makeService()
        for chance: Int16 in [-100, -10, -1] {
            let outcome = service.resolve(chance: chance)
            XCTAssertFalse(outcome.success, "chance=\(chance) must auto-fail")
            XCTAssertNil(outcome.roll, "chance=\(chance) must not produce a roll")
        }
    }

    func testZeroChance_AutoFailsAndDoesNotRoll() {
        let outcome = makeService().resolve(chance: 0)
        XCTAssertFalse(outcome.success, "chance=0 must auto-fail")
        XCTAssertNil(outcome.roll, "chance=0 must not produce a roll")
    }

    func testExactly100Chance_AutoSucceedsAndDoesNotRoll() {
        let outcome = makeService().resolve(chance: 100)
        XCTAssertTrue(outcome.success, "chance=100 must auto-succeed")
        XCTAssertNil(outcome.roll, "chance=100 must not produce a roll")
    }

    func testAbove100Chance_AutoSucceedsAndDoesNotRoll() {
        let service = makeService()
        for chance: Int16 in [101, 150, 1_000] {
            let outcome = service.resolve(chance: chance)
            XCTAssertTrue(outcome.success, "chance=\(chance) must auto-succeed")
            XCTAssertNil(outcome.roll, "chance=\(chance) must not produce a roll")
        }
    }

    func testNormalChance_AlwaysProducesRollIn1To100() {
        let service = makeService()
        for _ in 0..<200 {
            let outcome = service.resolve(chance: 50)
            guard let roll = outcome.roll else {
                XCTFail("chance=50 must produce a roll")
                return
            }
            XCTAssertGreaterThanOrEqual(roll, 1)
            XCTAssertLessThanOrEqual(roll, 100)
        }
    }

    /// `success == roll ≤ chance`. Run a thousand rolls at chance=50 and
    /// verify every individual outcome respects the rule.
    func testNormalChance_SuccessFollowsRollComparison() {
        let service = makeService()
        for _ in 0..<1000 {
            let outcome = service.resolve(chance: 50)
            guard let roll = outcome.roll else {
                XCTFail("chance=50 must produce a roll")
                return
            }
            XCTAssertEqual(outcome.success, roll <= 50)
        }
    }

    /// Monte Carlo: empirical success rate for chance=70 over 5000 rolls
    /// should be within a few percent of 70%.
    func testNormalChance_EmpiricalRateMatchesChance() {
        let service = makeService()
        let trials = 5000
        var hits = 0
        for _ in 0..<trials {
            if service.resolve(chance: 70).success { hits += 1 }
        }
        let observed = Double(hits) / Double(trials)
        XCTAssertEqual(observed, 0.70, accuracy: 0.03,
                       "Expected ≈ 70% success rate, got \(observed)")
    }

    /// Boundary edge: chance=1 should produce a roll and succeed exactly on
    /// roll==1. We can't pin one specific outcome but can verify low rate.
    func testChance1_VeryLowSuccessRate() {
        let service = makeService()
        let trials = 5000
        var hits = 0
        for _ in 0..<trials {
            if service.resolve(chance: 1).success { hits += 1 }
        }
        let observed = Double(hits) / Double(trials)
        XCTAssertEqual(observed, 0.01, accuracy: 0.015)
    }

    /// Boundary edge: chance=99 should succeed almost always.
    func testChance99_VeryHighSuccessRate() {
        let service = makeService()
        let trials = 5000
        var hits = 0
        for _ in 0..<trials {
            if service.resolve(chance: 99).success { hits += 1 }
        }
        let observed = Double(hits) / Double(trials)
        XCTAssertEqual(observed, 0.99, accuracy: 0.015)
    }

    /// Same seed → same roll sequence. The whole point of routing randomness
    /// through `\.withRandomNumberGenerator`.
    func testSeededGenerator_IsReproducible() {
        func rollSequence() -> [Int?] {
            withDependencies {
                $0.withRandomNumberGenerator = WithRandomNumberGenerator(
                    SeededRandomNumberGenerator(seed: 42)
                )
            } operation: {
                let service = ElfChanceRollService()
                return (0..<20).map { _ in service.resolve(chance: 50).roll }
            }
        }
        XCTAssertEqual(rollSequence(), rollSequence())
    }
}

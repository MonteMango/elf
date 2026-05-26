//
//  ElfEnduranceDamageReductionDistributionStrategyTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import XCTest
@testable import elf_Kit

/// Step 1: the endurance reduction table is a 1:1 copy of the strength table.
/// These tests pin that invariant on every level the strength suite covers,
/// so a future tuning pass can't silently drift the two tables apart without
/// failing here.
final class ElfEnduranceDamageReductionDistributionStrategyTests: XCTestCase {

    private let strategy = ElfEnduranceDamageReductionDistributionStrategy()

    // MARK: - Predefined Distributions (1-52)

    func testDistributionForEndurance1() async {
        let result = await strategy.distribution(for: 1)
        XCTAssertEqual(result.values, [0, 1])
        XCTAssertEqual(result.weights, [3, 1])
    }

    func testDistributionForEndurance2() async {
        let result = await strategy.distribution(for: 2)
        XCTAssertEqual(result.values, [0, 1])
        XCTAssertEqual(result.weights, [3, 2])
    }

    func testDistributionForEndurance3() async {
        let result = await strategy.distribution(for: 3)
        XCTAssertEqual(result.values, [0, 1])
        XCTAssertEqual(result.weights, [3, 3])
    }

    func testDistributionForEndurance4() async {
        let result = await strategy.distribution(for: 4)
        XCTAssertEqual(result.values, [0, 1, 2])
        XCTAssertEqual(result.weights, [3, 3, 1])
    }

    func testDistributionForEndurance12() async {
        let result = await strategy.distribution(for: 12)
        XCTAssertEqual(result.values, [0, 1, 2, 3, 4])
        XCTAssertEqual(result.weights, [3, 3, 3, 3, 3])
    }

    func testDistributionForEndurance24() async {
        let result = await strategy.distribution(for: 24)
        XCTAssertEqual(result.values, [3, 4, 5])
        XCTAssertEqual(result.weights, [3, 3, 3])
    }

    func testDistributionForEndurance36() async {
        // Max value reachable by def-style at lvl 12 (endurance 36 from levelling).
        let result = await strategy.distribution(for: 36)
        XCTAssertEqual(result.values, [5, 6, 7])
        XCTAssertEqual(result.weights, [3, 3, 3])
    }

    func testDistributionForEndurance45() async {
        let result = await strategy.distribution(for: 45)
        XCTAssertEqual(result.values, [7, 8])
        XCTAssertEqual(result.weights, [3, 3])
    }

    func testDistributionForEndurance48() async {
        let result = await strategy.distribution(for: 48)
        XCTAssertEqual(result.values, [8])
        XCTAssertEqual(result.weights, [1])
    }

    func testDistributionForEndurance50() async {
        let result = await strategy.distribution(for: 50)
        XCTAssertEqual(result.values, [8, 9])
        XCTAssertEqual(result.weights, [3, 2])
    }

    func testDistributionForEndurance52() async {
        let result = await strategy.distribution(for: 52)
        XCTAssertEqual(result.values, [9])
        XCTAssertEqual(result.weights, [1])
    }

    // MARK: - Extended Distributions (53+)

    func testDistributionForEndurance53() async {
        // like 45 but with baseValue 8
        let result = await strategy.distribution(for: 53)
        XCTAssertEqual(result.values, [8, 9])
        XCTAssertEqual(result.weights, [3, 3])
    }

    func testDistributionForEndurance60() async {
        // like 52 but with baseValue 8
        let result = await strategy.distribution(for: 60)
        XCTAssertEqual(result.values, [10])
        XCTAssertEqual(result.weights, [1])
    }

    func testDistributionForEndurance100() async {
        // 100 = 45 + 55 = 45 + 6*8 + 7
        // baseValue = 7 + 6 = 13, cyclePosition = 7
        let result = await strategy.distribution(for: 100)
        XCTAssertEqual(result.values, [15])
        XCTAssertEqual(result.weights, [1])
    }
}

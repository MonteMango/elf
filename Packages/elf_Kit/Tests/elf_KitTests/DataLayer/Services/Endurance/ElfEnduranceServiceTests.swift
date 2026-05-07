//
//  ElfEnduranceServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import XCTest
@testable import elf_Kit

/// Tests for `ElfEnduranceService` block-cost formula.
///
/// Canonical formula from `attributes.md`:
/// `cost = round( pool / ( pool/baseCost + endurance/2 ) )`
///
/// Tests are written against properties of the formula rather than
/// hard-coded magic numbers so they remain valid if
/// `GameMechanicsConstants.startingEP` is tuned.
final class ElfEnduranceServiceTests: XCTestCase {

    private let service = ElfEnduranceService()
    private var pool: Int { GameMechanicsConstants.startingEP }

    // MARK: - No endurance → baseCost unchanged

    func test2H_NoEndurance_CostEqualsBaseCost() {
        XCTAssertEqual(service.calculateBlockCost(baseCost: 400, defenderEndurance: 0), 400)
    }

    func test1H_NoEndurance_CostEqualsBaseCost() {
        XCTAssertEqual(service.calculateBlockCost(baseCost: 200, defenderEndurance: 0), 200)
    }

    // MARK: - Endurance reduces cost

    func test2H_Endurance10_CostStrictlyLessThanBaseCost() {
        XCTAssertLessThan(service.calculateBlockCost(baseCost: 400, defenderEndurance: 10), 400)
    }

    func test1H_Endurance36_CostStrictlyLessThanBaseCost() {
        XCTAssertLessThan(service.calculateBlockCost(baseCost: 200, defenderEndurance: 36), 200)
    }

    func testHigherEnduranceProducesLowerOrEqualCost() {
        let costLow = service.calculateBlockCost(baseCost: 400, defenderEndurance: 5)
        let costHigh = service.calculateBlockCost(baseCost: 400, defenderEndurance: 30)
        XCTAssertGreaterThan(costLow, costHigh)
    }

    // MARK: - Edge cases

    func testZeroBaseCost_ReturnsZero() {
        // No weapon / hero attacking bare-handed → no EP cost imposed.
        XCTAssertEqual(service.calculateBlockCost(baseCost: 0, defenderEndurance: 10), 0)
    }

    func testNegativeEndurance_TreatedAsZero() {
        // Defensive: negative endurance shouldn't inflate the cost.
        let cost = service.calculateBlockCost(baseCost: 400, defenderEndurance: -5)
        XCTAssertEqual(cost, 400)
    }

    // MARK: - Block count derivation (matches attributes.md design intent)

    func test2H_Endurance0_BlockCountEqualsPoolDividedByBaseCost() {
        let cost = service.calculateBlockCost(baseCost: 400, defenderEndurance: 0)
        XCTAssertEqual(pool / cost, pool / 400)
    }

    func testEndurance2_AddsOneEffectiveBlock() {
        // attributes.md: "every +2 endurance grants +1 effective block".
        let baseBlocks = pool / service.calculateBlockCost(baseCost: 400, defenderEndurance: 0)
        let endurance2Blocks = pool / service.calculateBlockCost(baseCost: 400, defenderEndurance: 2)
        XCTAssertEqual(endurance2Blocks, baseBlocks + 1)
    }

    // MARK: - Defensive bounds

    /// Extreme endurance must never collapse the cost to 0 — that would mean
    /// "free blocks" and break the `blockCost > 0` guard in the combat
    /// calculator, which currently relies on `0` to mean "no protection".
    /// Chosen value (10_000) is far beyond any reachable in-game endurance
    /// (max ~36 at lvl 12), but sets a hard lower bound on the formula.
    func testExtremeEndurance_DoesNotProduceZeroCost() {
        let cost = service.calculateBlockCost(baseCost: 400, defenderEndurance: 10_000)
        XCTAssertGreaterThanOrEqual(cost, 1, "Cost must clamp to ≥ 1 — never collapse to 0 from endurance scaling")
    }
}

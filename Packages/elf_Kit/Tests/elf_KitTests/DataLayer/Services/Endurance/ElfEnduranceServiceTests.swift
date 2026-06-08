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
/// `cost = round( pool / ( pool/baseCost + endurance × blocksPerEndurancePoint ) )`
///
/// Tests are written against properties of the formula rather than
/// hard-coded magic numbers so they remain valid if
/// `GameMechanicsConstants.startingEP` or `blocksPerEndurancePoint` is tuned.
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

    func testEndurance_OneBlockGain_MatchesBlocksPerEndurancePoint() {
        // attributes.md: each Endurance point grants `blocksPerEndurancePoint`
        // effective blocks. Pick the smallest endurance that yields exactly
        // +1 block of capacity. The naive `round(1/blocksPerPoint)` truncates
        // when the ratio is fractional (e.g. 0.3 → 1/0.3 ≈ 3.33 → 3), so we
        // must round UP: 3 endurance still only gives 6 blocks at baseCost 400,
        // 4 endurance is the first that reliably crosses to 7.
        let blocksPerPoint = GameMechanicsConstants.blocksPerEndurancePoint
        guard blocksPerPoint > 0 else {
            XCTFail("blocksPerEndurancePoint must be > 0 for this test to be meaningful")
            return
        }
        let enduranceForOneBlock = Int((1.0 / blocksPerPoint).rounded(.up))

        let baseBlocks = pool / service.calculateBlockCost(baseCost: 400, defenderEndurance: 0)
        let withEnduranceBlocks = pool / service.calculateBlockCost(baseCost: 400, defenderEndurance: enduranceForOneBlock)
        XCTAssertEqual(withEnduranceBlocks, baseBlocks + 1)
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

    // MARK: - Attacker strength burn (3-arg path)

    /// Symmetric counterpart to `testHigherEnduranceProducesLowerOrEqualCost`:
    /// stronger attackers should burn effective blocks from the defender's
    /// pool, raising per-block EP cost.
    func testHigherAttackerStrength_RaisesBlockCost() {
        let weakAttacker = service.calculateBlockCost(
            baseCost: 400, defenderEndurance: 36, attackerStrength: 0
        )
        let strongAttacker = service.calculateBlockCost(
            baseCost: 400, defenderEndurance: 36, attackerStrength: 24
        )
        XCTAssertGreaterThan(strongAttacker, weakAttacker,
                             "Higher attacker strength must raise per-block EP cost")
    }

    /// Stronger attackers should monotonically push the cost up (each
    /// `blocksLostPerAttackerStrength` burns one effective block).
    func testAttackerStrength_IsMonotonicallyCostly() {
        let costs = (0...20).map { strength in
            service.calculateBlockCost(baseCost: 400, defenderEndurance: 12, attackerStrength: strength)
        }
        for index in 1..<costs.count {
            XCTAssertGreaterThanOrEqual(
                costs[index],
                costs[index - 1],
                "Cost must be non-decreasing in attacker strength (strength=\(index))"
            )
        }
    }

    /// Negative attacker strength must be clamped to 0 — defensive against
    /// upstream bugs.
    func testNegativeAttackerStrength_TreatedAsZero() {
        let baseline = service.calculateBlockCost(
            baseCost: 400, defenderEndurance: 12, attackerStrength: 0
        )
        let negative = service.calculateBlockCost(
            baseCost: 400, defenderEndurance: 12, attackerStrength: -10
        )
        XCTAssertEqual(negative, baseline)
    }

    /// Attacker strength alone (no defender endurance) must still bite —
    /// the defender's effective block count drops below the base
    /// `pool / baseCost`.
    func testAttackerStrength_OnZeroEnduranceDefender_RaisesCostAboveBase() {
        let baseline = service.calculateBlockCost(
            baseCost: 400, defenderEndurance: 0, attackerStrength: 0
        )
        let withStrength = service.calculateBlockCost(
            baseCost: 400, defenderEndurance: 0, attackerStrength: 12
        )
        XCTAssertGreaterThan(withStrength, baseline,
                             "Strength must raise cost even when defender has zero endurance")
    }

    /// Floor invariant: when an attacker out-strengths the defender's
    /// endurance budget by a wide margin, the denominator clamps at 1.0 →
    /// cost = pool, no further degradation. Must never go negative or zero.
    func testExtremeAttackerStrength_CostClampedToPool() {
        let cost = service.calculateBlockCost(
            baseCost: 400, defenderEndurance: 0, attackerStrength: 10_000
        )
        XCTAssertGreaterThanOrEqual(cost, 1)
        XCTAssertLessThanOrEqual(cost, pool, "Cost must clamp at the EP pool when denominator hits the floor")
    }

    /// The test-only 2-arg shorthand (see `EnduranceService+TestConvenience`)
    /// must equal the 3-arg call with `attackerStrength: 0`.
    func testConvenienceOverload_MatchesThreeArgWithZeroStrength() {
        let twoArg = service.calculateBlockCost(baseCost: 400, defenderEndurance: 12)
        let threeArg = service.calculateBlockCost(
            baseCost: 400, defenderEndurance: 12, attackerStrength: 0
        )
        XCTAssertEqual(twoArg, threeArg)
    }
}

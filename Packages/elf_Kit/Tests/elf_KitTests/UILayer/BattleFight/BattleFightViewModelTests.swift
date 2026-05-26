//
//  BattleFightViewModelTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import XCTest
@testable import elf_Kit

/// Focused on the proportional-rescaling helper used after a battle buff
/// shifts the effective HP/MP cap. The full `applyBattleBuff` integration is
/// covered by exercising the helper directly — wiring a `BattleFightViewModel`
/// requires a `Battle` and a battery of DI overrides that would dwarf the
/// single decision under test.
@MainActor
final class BattleFightViewModelTests: XCTestCase {

    // MARK: - scaledVital

    func testScaledVital_PreservesFractionOnCapIncrease() {
        // 50 / 100 → ? / 120 = 60 (50 × 120 / 100)
        XCTAssertEqual(
            BattleFightViewModel.scaledVital(current: 50, oldMax: 100, newMax: 120),
            60
        )
    }

    func testScaledVital_PreservesFractionOnCapDecrease() {
        // 60 / 120 → ? / 100 = 50 (60 × 100 / 120 = 50)
        XCTAssertEqual(
            BattleFightViewModel.scaledVital(current: 60, oldMax: 120, newMax: 100),
            50
        )
    }

    func testScaledVital_RoundsHalfUp() {
        // 25 / 100 → ? / 33 → 25 × 33 / 100 = 8.25 → rounds half-up to 8
        XCTAssertEqual(
            BattleFightViewModel.scaledVital(current: 25, oldMax: 100, newMax: 33),
            8
        )
        // 1 / 2 → ? / 3 → 1 × 3 / 2 = 1.5 → rounds half-up to 2
        XCTAssertEqual(
            BattleFightViewModel.scaledVital(current: 1, oldMax: 2, newMax: 3),
            2
        )
    }

    func testScaledVital_ClampsToNewCap() {
        // 100 / 100 → ? / 80 = 80 (full HP stays full, clamped)
        XCTAssertEqual(
            BattleFightViewModel.scaledVital(current: 100, oldMax: 100, newMax: 80),
            80
        )
    }

    func testScaledVital_NeverExceedsNewCapFromRounding() {
        // Pathological: current already at oldMax, half-up could nudge past newMax.
        XCTAssertEqual(
            BattleFightViewModel.scaledVital(current: 7, oldMax: 7, newMax: 7),
            7
        )
    }

    func testScaledVital_DeadCombatantStaysDead() {
        // currentHP == 0 → stays 0 regardless of cap change.
        XCTAssertEqual(
            BattleFightViewModel.scaledVital(current: 0, oldMax: 100, newMax: 150),
            0
        )
    }

    func testScaledVital_ZeroOldCap_AvoidsDivByZero() {
        // oldMax == 0 short-circuits to min(current, newMax). Guards against the
        // edge where MP is genuinely zero on a no-mana combatant and a buff
        // raises maxMP above zero.
        XCTAssertEqual(
            BattleFightViewModel.scaledVital(current: 0, oldMax: 0, newMax: 50),
            0
        )
        XCTAssertEqual(
            BattleFightViewModel.scaledVital(current: 5, oldMax: 0, newMax: 50),
            5
        )
        XCTAssertEqual(
            BattleFightViewModel.scaledVital(current: 60, oldMax: 0, newMax: 50),
            50
        )
    }

    func testScaledVital_BothCapsZero_ReturnsZero() {
        XCTAssertEqual(
            BattleFightViewModel.scaledVital(current: 0, oldMax: 0, newMax: 0),
            0
        )
    }
}

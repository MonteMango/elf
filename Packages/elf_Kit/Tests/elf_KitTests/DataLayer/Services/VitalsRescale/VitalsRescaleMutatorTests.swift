//
//  VitalsRescaleMutatorTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import XCTest
@testable import elf_Kit

/// Tests the `VitalsRescaleMutator` extracted from `BattleFightViewModel`
/// (T21, architecture-hardening review finding #1): the proportional HP/MP
/// rescale that ran after a buff shifted a combatant's effective cap. Exercised
/// directly against the injected type via `rescaleVitals(combatant:before:after:)`
/// — the same edge cases the prior `BattleFightViewModel.scaledVital` static
/// tests covered, now proven through the public domain-shaped API instead of
/// the raw math helper.
final class VitalsRescaleMutatorTests: XCTestCase {

    private let mutator = DefaultVitalsRescaleMutator()

    // MARK: - Fixtures

    private func makeCombatant(currentHP: Int, currentMP: Int) -> CombatantSnapshot {
        CombatantSnapshot(
            source: .synthetic,
            name: "C",
            imageName: "img",
            combatantType: .elf,
            currentHP: currentHP,
            currentMP: currentMP,
            currentEP: 0,
            maxEP: 0,
            baseHeroAttributes: HeroAttributes(),
            attacks: [],
            defensePoints: 0,
            armorValues: [:]
        )
    }

    private func attributes(hitPoints: Int, manaPoints: Int) -> HeroAttributes {
        HeroAttributes(
            hitPoints: Attribute(Int16(hitPoints)),
            manaPoints: Attribute(Int16(manaPoints)),
            agility: 0, strength: 0, power: 0, instinct: 0, endurance: 0
        )
    }

    /// Rescales HP from `oldMax` → `newMax` (MP held fixed at 0/0, a no-op
    /// channel) and returns the resulting `currentHP` — mirrors the prior
    /// `scaledVital(current:oldMax:newMax:)` static helper's contract.
    private func rescaledHP(current: Int, oldMax: Int, newMax: Int) -> Int {
        var combatant = makeCombatant(currentHP: current, currentMP: 0)
        mutator.rescaleVitals(
            combatant: &combatant,
            before: attributes(hitPoints: oldMax, manaPoints: 0),
            after: attributes(hitPoints: newMax, manaPoints: 0)
        )
        return combatant.currentHP
    }

    // MARK: - rescaleVitals (HP channel)

    func testRescaleVitals_PreservesFractionOnCapIncrease() {
        // 50 / 100 → ? / 120 = 60 (50 × 120 / 100)
        XCTAssertEqual(rescaledHP(current: 50, oldMax: 100, newMax: 120), 60)
    }

    func testRescaleVitals_PreservesFractionOnCapDecrease() {
        // 60 / 120 → ? / 100 = 50 (60 × 100 / 120 = 50)
        XCTAssertEqual(rescaledHP(current: 60, oldMax: 120, newMax: 100), 50)
    }

    func testRescaleVitals_RoundsHalfUp() {
        // 25 / 100 → ? / 33 → 25 × 33 / 100 = 8.25 → rounds half-up to 8
        XCTAssertEqual(rescaledHP(current: 25, oldMax: 100, newMax: 33), 8)
        // 1 / 2 → ? / 3 → 1 × 3 / 2 = 1.5 → rounds half-up to 2
        XCTAssertEqual(rescaledHP(current: 1, oldMax: 2, newMax: 3), 2)
    }

    func testRescaleVitals_ClampsToNewCap() {
        // 100 / 100 → ? / 80 = 80 (full HP stays full, clamped)
        XCTAssertEqual(rescaledHP(current: 100, oldMax: 100, newMax: 80), 80)
    }

    func testRescaleVitals_NeverExceedsNewCapFromRounding() {
        // Pathological: current already at oldMax, half-up could nudge past newMax.
        XCTAssertEqual(rescaledHP(current: 7, oldMax: 7, newMax: 7), 7)
    }

    func testRescaleVitals_DeadCombatantStaysDead() {
        // currentHP == 0 → stays 0 regardless of cap change.
        XCTAssertEqual(rescaledHP(current: 0, oldMax: 100, newMax: 150), 0)
    }

    func testRescaleVitals_ZeroOldCap_AvoidsDivByZero() {
        // oldMax == 0 short-circuits to min(current, newMax). Guards against the
        // edge where MP is genuinely zero on a no-mana combatant and a buff
        // raises maxMP above zero.
        XCTAssertEqual(rescaledHP(current: 0, oldMax: 0, newMax: 50), 0)
        XCTAssertEqual(rescaledHP(current: 5, oldMax: 0, newMax: 50), 5)
        XCTAssertEqual(rescaledHP(current: 60, oldMax: 0, newMax: 50), 50)
    }

    func testRescaleVitals_BothCapsZero_ReturnsZero() {
        XCTAssertEqual(rescaledHP(current: 0, oldMax: 0, newMax: 0), 0)
    }

    // MARK: - rescaleVitals (MP channel, independent of HP)

    func testRescaleVitals_ScalesMPIndependentlyOfHP() {
        var combatant = makeCombatant(currentHP: 100, currentMP: 50)
        mutator.rescaleVitals(
            combatant: &combatant,
            before: attributes(hitPoints: 100, manaPoints: 100),
            after: attributes(hitPoints: 100, manaPoints: 120)
        )
        XCTAssertEqual(combatant.currentHP, 100, "HP cap unchanged, current unchanged")
        XCTAssertEqual(combatant.currentMP, 60, "50 × 120 / 100 = 60")
    }
}

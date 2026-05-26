//
//  DefaultPointStatusFormatterTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import XCTest
@testable import elf_Kit

/// Pins down `DefaultPointStatusFormatter`'s text output for every
/// `PointStatus` case. The damage number rendered MUST always come from
/// `PointStatus.damageTakenValue` (single source of truth) — these tests
/// catch regressions where a future refactor inlines arithmetic again.
final class DefaultPointStatusFormatterTests: XCTestCase {

    private let formatter = DefaultPointStatusFormatter()

    // MARK: - shortLabel

    func testShortLabel_Dodged_ReturnsDodge() {
        XCTAssertEqual(formatter.shortLabel(for: .dodged(wasCrit: false)), "dodge")
        XCTAssertEqual(formatter.shortLabel(for: .dodged(wasCrit: true)), "dodge")
    }

    func testShortLabel_Hit_ReturnsDamageNumber() {
        let status: PointStatus = .hit(
            weaponDamage: 10, strengthDamage: 5, enduranceReduction: 2, defenderArmor: 3
        )
        XCTAssertEqual(formatter.shortLabel(for: status), "\(status.damageTakenValue)")
        XCTAssertEqual(formatter.shortLabel(for: status), "10")
    }

    func testShortLabel_CritHit_ReturnsCritPrefixAndDamage() {
        let status: PointStatus = .critHit(
            weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 2,
            multiplier: 2.0, epSpent: 0
        )
        // weapon 10 × 2.0 = 20 + str 5 − end 0 − armor 2 = 23
        XCTAssertEqual(formatter.shortLabel(for: status), "crit \(status.damageTakenValue)")
        XCTAssertEqual(formatter.shortLabel(for: status), "crit 23")
    }

    func testShortLabel_CritHit_PinsAgainstDamageTakenValue() {
        // Sanity pin: shortLabel must reuse damageTakenValue verbatim.
        // If this test fails, formatter has re-introduced an inline formula.
        let status: PointStatus = .critHit(
            weaponDamage: 13, strengthDamage: 7, enduranceReduction: 4, defenderArmor: 1,
            multiplier: 1.5, epSpent: 100
        )
        let expected = "crit \(status.damageTakenValue)"
        XCTAssertEqual(formatter.shortLabel(for: status), expected)
    }

    func testShortLabel_Blocked_ReturnsBlock() {
        XCTAssertEqual(formatter.shortLabel(for: .blocked(wasCrit: false, epSpent: 200)), "block")
        XCTAssertEqual(formatter.shortLabel(for: .blocked(wasCrit: true, epSpent: 200)), "block")
    }

    func testShortLabel_WeakBlocked_NoCrit_ReturnsWeakAndFinalDamage() {
        let status: PointStatus = .weakBlocked(
            weaponDamage: 10, strengthDamage: 6, enduranceReduction: 0, defenderArmor: 4,
            multiplier: 1.0, finalDamage: 7, wasCrit: false
        )
        XCTAssertEqual(formatter.shortLabel(for: status), "weak 7")
    }

    func testShortLabel_WeakBlocked_Crit_ReturnsWeakAndFinalDamageWithBang() {
        let status: PointStatus = .weakBlocked(
            weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 2,
            multiplier: 1.25, finalDamage: 15, wasCrit: true
        )
        XCTAssertEqual(formatter.shortLabel(for: status), "weak 15!")
    }

    func testShortLabel_Nothing_ReturnsNil() {
        XCTAssertNil(formatter.shortLabel(for: .nothing))
    }

    // MARK: - debugLine

    func testDebugLine_Blocked_IncludesEPSpent() {
        let line = formatter.debugLine(for: .blocked(wasCrit: false, epSpent: 250))
        XCTAssertTrue(line.contains("BLOCKED"))
        XCTAssertTrue(line.contains("-250 EP"))
    }

    func testDebugLine_Hit_IncludesAllComponents() {
        let status: PointStatus = .hit(
            weaponDamage: 10, strengthDamage: 5, enduranceReduction: 2, defenderArmor: 3
        )
        let line = formatter.debugLine(for: status)
        XCTAssertTrue(line.contains("HIT"))
        XCTAssertTrue(line.contains("\(status.damageTakenValue) damage"))
        XCTAssertTrue(line.contains("weapon=10"))
        XCTAssertTrue(line.contains("str=5"))
        XCTAssertTrue(line.contains("end_red=2"))
        XCTAssertTrue(line.contains("armor=3"))
    }

    func testDebugLine_CritHit_IncludesMultiplierAndEPSuffixWhenSpent() {
        let status: PointStatus = .critHit(
            weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 2,
            multiplier: 2.0, epSpent: 200
        )
        let line = formatter.debugLine(for: status)
        XCTAssertTrue(line.contains("CRIT HIT"))
        XCTAssertTrue(line.contains("\(status.damageTakenValue) damage"))
        XCTAssertTrue(line.contains("weapon=10x2.0"))
        XCTAssertTrue(line.contains("-200 EP"))
    }

    func testDebugLine_CritHit_NoEPSuffixWhenNotSpent() {
        let status: PointStatus = .critHit(
            weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 2,
            multiplier: 2.0, epSpent: 0
        )
        let line = formatter.debugLine(for: status)
        XCTAssertFalse(line.contains("EP"), "No EP suffix when epSpent == 0")
    }

    func testDebugLine_WeakBlocked_NoCrit_NoCritTag() {
        let status: PointStatus = .weakBlocked(
            weaponDamage: 10, strengthDamage: 6, enduranceReduction: 0, defenderArmor: 4,
            multiplier: 1.0, finalDamage: 7, wasCrit: false
        )
        let line = formatter.debugLine(for: status)
        XCTAssertTrue(line.contains("WEAK BLOCK"))
        XCTAssertTrue(line.contains("7 damage"))
        XCTAssertFalse(line.contains("crit×"))
    }

    func testDebugLine_WeakBlocked_Crit_HasCritTag() {
        let status: PointStatus = .weakBlocked(
            weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 2,
            multiplier: 1.25, finalDamage: 15, wasCrit: true
        )
        let line = formatter.debugLine(for: status)
        XCTAssertTrue(line.contains("WEAK BLOCK"))
        XCTAssertTrue(line.contains("15 damage"))
        XCTAssertTrue(line.contains("crit×1.25"))
    }

    func testDebugLine_Dodged_ReturnsDodgedString() {
        XCTAssertTrue(formatter.debugLine(for: .dodged(wasCrit: false)).contains("DODGED"))
    }

    func testDebugLine_Nothing_ReturnsNothingString() {
        XCTAssertTrue(formatter.debugLine(for: .nothing).contains("Nothing"))
    }
}

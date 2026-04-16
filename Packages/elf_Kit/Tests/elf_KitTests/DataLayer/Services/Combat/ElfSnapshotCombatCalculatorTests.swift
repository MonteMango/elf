//
//  ElfSnapshotCombatCalculatorTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import XCTest
@testable import elf_Kit

/// Tests for ElfSnapshotCombatCalculator
///
/// Combat logic:
/// - Attack on defended point: Check crit to break block
/// - Attack on undefended point: Check dodge, then crit/normal hit
/// - No attack on point: Nothing status
final class ElfSnapshotCombatCalculatorTests: XCTestCase {

    // MARK: - Mock Services

    /// Mock Damage Service with controllable output
    final class MockDamageService: DamageService, @unchecked Sendable {
        nonisolated(unsafe) var strengthDamageToReturn: Int16 = 5
        nonisolated(unsafe) var weaponDamageToReturn: Int16 = 10

        func getMinMaxStrengthDamage(_ strengthAttribute: Int16) -> (minDmg: Int16, maxDmg: Int16)? {
            return (0, strengthDamageToReturn)
        }

        func getStrengthDamageDistribution(_ strengthAttribute: Int16) -> (distribution: [Int16], weights: [Int]) {
            return ([strengthDamageToReturn], [1])
        }

        func getRandomStrengthDamage(_ strengthAttribute: Int16) -> Int16 {
            return strengthDamageToReturn
        }

        func getWeaponDamage(weaponId: UUID?) -> (minDmg: Int16, maxDmg: Int16)? {
            return (weaponDamageToReturn, weaponDamageToReturn)
        }

        func getRandomWeaponDamage(weaponId: UUID?) -> Int16 {
            return weaponDamageToReturn
        }

        func calculateTotalDamage(from pointStatus: [BodyPart: PointStatus]) -> Int {
            var total = 0
            for (_, status) in pointStatus {
                switch status {
                case .hit(let weaponDmg, let strengthDmg, let armor):
                    total += max(0, weaponDmg + strengthDmg - armor)
                case .critHit(let weaponDmg, let strengthDmg, let armor, let multiplier):
                    total += max(0, Int(Double(weaponDmg + strengthDmg) * multiplier) - armor)
                default:
                    break
                }
            }
            return total
        }
    }

    /// Mock Dodge Service with controllable output
    final class MockDodgeService: DodgeService, @unchecked Sendable {
        nonisolated(unsafe) var shouldDodge: Bool = false

        func calculateDodge(agility: Int16, instinct: Int16) -> DodgeCalculationResult {
            let distribution = DodgeDistribution(
                minimumChance: 0,
                maximumChance: 50,
                rangeValues: [25],
                rangeWeights: [1]
            )
            return DodgeCalculationResult(
                distribution: distribution,
                selectedChance: 25,
                stage2Roll: shouldDodge ? 10 : 90,
                success: shouldDodge
            )
        }
    }

    /// Mock Crit Service with controllable output
    final class MockCritService: CritService, @unchecked Sendable {
        nonisolated(unsafe) var shouldCrit: Bool = false
        nonisolated(unsafe) var critMultiplier: Double = 1.5

        func calculateCrit(power: Int16, instinct: Int16, defenderAgility: Int16) -> CritCalculationResult {
            let distribution = CritDistribution(
                minimumChance: 10,
                maximumChance: 50,
                rangeValues: [30],
                rangeWeights: [1]
            )
            let multiplierDistribution = CritMultiplierDistribution()

            return CritCalculationResult(
                distribution: distribution,
                selectedChance: 30,
                stage2Roll: shouldCrit ? 10 : 90,
                success: shouldCrit,
                multiplierDistribution: multiplierDistribution,
                adjustedMultiplierDistribution: multiplierDistribution,
                critMultiplierDecreaser: 0,
                multiplierRoll: shouldCrit ? 50 : nil,
                selectedMultiplier: shouldCrit ? critMultiplier : 1.0
            )
        }
    }

    /// Mock Debug Logger (no-op)
    final class MockDebugLogger: DebugBattleLogger {
        func logRoundStart(roundNumber: Int, playerSnapshot: CombatantSnapshot, botSnapshot: CombatantSnapshot, playerAttack: [BodyPart], playerDefense: [BodyPart], botAttack: [BodyPart], botDefense: [BodyPart]) {}
        func logDodgeCalculation(defender: String, result: DodgeCalculationResult, agility: Int16, instinct: Int16) {}
        func logCritCalculation(attacker: String, result: CritCalculationResult, power: Int16, instinct: Int16) {}
        func logBodyPartCalculation(attacker: String, defender: String, bodyPart: BodyPart, isAttacked: Bool, isDefended: Bool, baseDamage: Int?, armor: Int?, finalDamage: Int?, finalStatus: PointStatus) {}
        func logRoundEnd(roundNumber: Int, playerOldHP: Int, playerNewHP: Int, botOldHP: Int, botNewHP: Int, playerResults: [BodyPart: PointStatus], botResults: [BodyPart: PointStatus]) {}
    }

    // MARK: - Test Helpers

    private var mockDamageService: MockDamageService!
    private var mockDodgeService: MockDodgeService!
    private var mockCritService: MockCritService!
    private var mockLogger: MockDebugLogger!

    private func makeCalculator() -> ElfSnapshotCombatCalculator {
        return ElfSnapshotCombatCalculator(
            damageService: mockDamageService,
            dodgeService: mockDodgeService,
            critService: mockCritService,
            debugLogger: mockLogger
        )
    }

    private func makeSnapshot(
        agility: Int = 10,
        strength: Int = 10,
        power: Int = 10,
        intuition: Int = 10,
        minimumAttack: Int = 10,
        maximumAttack: Int = 10,
        armor: [BodyPart: Int] = [:]
    ) -> CombatantSnapshot {
        return CombatantSnapshot(
            id: UUID(),
            sourceId: UUID(),
            name: "Test",
            imageName: "",
            combatantType: .elf,
            currentHP: 100,
            maxHP: 100,
            strength: strength,
            agility: agility,
            power: power,
            intuition: intuition,
            attackPoints: 1,
            defensePoints: 2,
            minimumAttack: minimumAttack,
            maximumAttack: maximumAttack,
            armorValues: armor
        )
    }

    override func setUp() {
        super.setUp()
        mockDamageService = MockDamageService()
        mockDodgeService = MockDodgeService()
        mockCritService = MockCritService()
        mockLogger = MockDebugLogger()
    }

    override func tearDown() {
        mockDamageService = nil
        mockDodgeService = nil
        mockCritService = nil
        mockLogger = nil
        super.tearDown()
    }

    // MARK: - Case 1: Attack on Defended Point (Block Check)

    func testAttackOnDefendedPoint_NoCrit_ResultsInBlock() async {
        // Given
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot(power: 20)
        let defender = makeSnapshot(intuition: 30)

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        // Then
        XCTAssertEqual(results[.head], .blocked(wasCrit: false))
    }

    func testAttackOnDefendedPoint_WithCrit_BreaksBlock() async {
        // Given
        mockCritService.shouldCrit = true
        mockCritService.critMultiplier = 2.0
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(power: 50, minimumAttack: 10, maximumAttack: 10)
        let defender = makeSnapshot(intuition: 10, armor: [.head: 3])

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        // Then
        if case .critHit(let weaponDmg, let strengthDmg, let armor, let multiplier) = results[.head] {
            XCTAssertEqual(weaponDmg, 10)
            XCTAssertEqual(strengthDmg, 5)
            XCTAssertEqual(armor, 3)
            XCTAssertEqual(multiplier, 2.0)
        } else {
            XCTFail("Expected critHit, got \(String(describing: results[.head]))")
        }
    }

    // MARK: - Case 2: Attack on Undefended Point

    func testAttackOnUndefendedPoint_Dodged_ResultsInDodge() async {
        // Given
        mockDodgeService.shouldDodge = true
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot()
        let defender = makeSnapshot(agility: 50)

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.body],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        // Then
        XCTAssertEqual(results[.body], .dodged(wasCrit: false))
    }

    func testAttackOnUndefendedPoint_DodgedWithCrit_ResultsInDodgeWithCritFlag() async {
        // Given
        mockDodgeService.shouldDodge = true
        mockCritService.shouldCrit = true
        let calculator = makeCalculator()
        let attacker = makeSnapshot(power: 80)
        let defender = makeSnapshot(agility: 50)

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.body],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        // Then
        XCTAssertEqual(results[.body], .dodged(wasCrit: true))
    }

    func testAttackOnUndefendedPoint_NotDodged_NoCrit_ResultsInNormalHit() async {
        // Given
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 6
        let calculator = makeCalculator()
        let attacker = makeSnapshot(strength: 20, minimumAttack: 12, maximumAttack: 12)
        let defender = makeSnapshot(armor: [.legs: 5])

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.legs],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        // Then
        if case .hit(let weaponDmg, let strengthDmg, let armor) = results[.legs] {
            XCTAssertEqual(weaponDmg, 12)
            XCTAssertEqual(strengthDmg, 6)
            XCTAssertEqual(armor, 5)
        } else {
            XCTFail("Expected hit, got \(String(describing: results[.legs]))")
        }
    }

    func testAttackOnUndefendedPoint_NotDodged_WithCrit_ResultsInCritHit() async {
        // Given
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = true
        mockCritService.critMultiplier = 1.5
        mockDamageService.strengthDamageToReturn = 8
        let calculator = makeCalculator()
        let attacker = makeSnapshot(power: 60, minimumAttack: 15, maximumAttack: 15)
        let defender = makeSnapshot(armor: [.rightHand: 2])

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.rightHand],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        // Then
        if case .critHit(let weaponDmg, let strengthDmg, let armor, let multiplier) = results[.rightHand] {
            XCTAssertEqual(weaponDmg, 15)
            XCTAssertEqual(strengthDmg, 8)
            XCTAssertEqual(armor, 2)
            XCTAssertEqual(multiplier, 1.5)
        } else {
            XCTFail("Expected critHit, got \(String(describing: results[.rightHand]))")
        }
    }

    // MARK: - Case 3: No Attack on Point

    func testNoAttackOnPoint_ResultsInNothing() async {
        // Given
        let calculator = makeCalculator()
        let attacker = makeSnapshot()
        let defender = makeSnapshot()

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.body],
            attacker: attacker,
            defender: defender
        )

        // Then
        XCTAssertEqual(results[.body], .nothing) // Defended but not attacked
        XCTAssertEqual(results[.legs], .nothing) // Neither attacked nor defended
        XCTAssertEqual(results[.leftHand], .nothing)
        XCTAssertEqual(results[.rightHand], .nothing)
    }

    // MARK: - Multiple Attack Points

    func testMultipleAttackPoints_EachProcessedIndependently() async {
        // Given
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(minimumAttack: 10, maximumAttack: 10)
        let defender = makeSnapshot(armor: [.head: 2, .body: 3])

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head, .body],
            defendingPoints: [.body],
            attacker: attacker,
            defender: defender
        )

        // Then
        // Head: attacked, not defended → hit
        if case .hit(let weaponDmg, let strengthDmg, let armor) = results[.head] {
            XCTAssertEqual(weaponDmg, 10)
            XCTAssertEqual(strengthDmg, 5)
            XCTAssertEqual(armor, 2)
        } else {
            XCTFail("Expected hit for head")
        }

        // Body: attacked and defended → blocked (no crit)
        XCTAssertEqual(results[.body], .blocked(wasCrit: false))
    }

    // MARK: - All Body Parts Covered

    func testAllBodyPartsReturnResults() async {
        // Given
        let calculator = makeCalculator()
        let attacker = makeSnapshot()
        let defender = makeSnapshot()

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        // Then: All 5 body parts should have results
        XCTAssertNotNil(results[.head])
        XCTAssertNotNil(results[.body])
        XCTAssertNotNil(results[.leftHand])
        XCTAssertNotNil(results[.rightHand])
        XCTAssertNotNil(results[.legs])
        XCTAssertEqual(results.count, 5)
    }

    // MARK: - Armor Application

    func testArmorIsAppliedFromDefender() async {
        // Given
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(minimumAttack: 10, maximumAttack: 10)
        let defender = makeSnapshot(armor: [.head: 8])

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        // Then
        if case .hit(_, _, let armor) = results[.head] {
            XCTAssertEqual(armor, 8, "Armor should be taken from defender's armor values")
        } else {
            XCTFail("Expected hit")
        }
    }

    func testZeroArmorWhenNotSpecified() async {
        // Given
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot()
        let defender = makeSnapshot(armor: [:]) // No armor

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.body],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        // Then
        if case .hit(_, _, let armor) = results[.body] {
            XCTAssertEqual(armor, 0, "Armor should be 0 when not specified")
        } else {
            XCTFail("Expected hit")
        }
    }
}

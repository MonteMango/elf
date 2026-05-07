//
//  ElfSnapshotCombatCalculatorTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import Dependencies
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
                case .critHit(let weaponDmg, let strengthDmg, let armor, let multiplier, _):
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

    /// Mock Endurance Service with controllable output. Defaults to identity
    /// (returns `baseCost` unchanged) so tests not focused on EP need no setup.
    final class MockEnduranceService: EnduranceService, @unchecked Sendable {
        nonisolated(unsafe) var costToReturn: Int? = nil

        func calculateBlockCost(baseCost: Int, defenderEndurance: Int) -> Int {
            costToReturn ?? baseCost
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

    // MARK: - Test Helpers

    private var mockDamageService: MockDamageService!
    private var mockDodgeService: MockDodgeService!
    private var mockCritService: MockCritService!
    private var mockEnduranceService: MockEnduranceService!

    private func makeCalculator() -> ElfSnapshotCombatCalculator {
        ElfSnapshotCombatCalculator()
    }

    private func makeSnapshot(
        agility: Int = 10,
        strength: Int = 10,
        power: Int = 10,
        intuition: Int = 10,
        endurance: Int = 0,
        currentEP: Int = GameMechanicsConstants.startingEP,
        attacks: [AttackProfile] = [
            AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)
        ],
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
            currentEP: currentEP,
            maxEP: GameMechanicsConstants.startingEP,
            strength: strength,
            agility: agility,
            power: power,
            intuition: intuition,
            endurance: endurance,
            attacks: attacks,
            defensePoints: 2,
            armorValues: armor
        )
    }

    /// Wrap every test in `withDependencies` so the calculator's @Dependency property
    /// wrappers resolve to per-test mocks. Mocks are created here (before
    /// `super.invokeTest()`) because `setUp` would otherwise run after the
    /// `withDependencies` block opens and leave the closure reading `nil`.
    /// `debugBattleLogger` is not overridden — its `testValue` is `NoOpDebugBattleLogger`.
    override func invokeTest() {
        let damage = MockDamageService()
        let dodge = MockDodgeService()
        let crit = MockCritService()
        let endurance = MockEnduranceService()
        self.mockDamageService = damage
        self.mockDodgeService = dodge
        self.mockCritService = crit
        self.mockEnduranceService = endurance

        withDependencies {
            $0.damageService = damage
            $0.dodgeService = dodge
            $0.critService = crit
            $0.enduranceService = endurance
        } operation: {
            super.invokeTest()
            self.mockDamageService = nil
            self.mockDodgeService = nil
            self.mockCritService = nil
            self.mockEnduranceService = nil
        }
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
        XCTAssertEqual(results[.head], .blocked(wasCrit: false, epSpent: 200))
    }

    func testAttackOnDefendedPoint_WithCrit_BreaksBlock() async {
        // Given
        mockCritService.shouldCrit = true
        mockCritService.critMultiplier = 2.0
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(power: 50, attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)])
        let defender = makeSnapshot(intuition: 10, armor: [.head: 3])

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        // Then
        if case .critHit(let weaponDmg, let strengthDmg, let armor, let multiplier, _) = results[.head] {
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
        let attacker = makeSnapshot(strength: 20, attacks: [AttackProfile(minimumAttack: 12, maximumAttack: 12, epBlockCost: 200)])
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
        let attacker = makeSnapshot(power: 60, attacks: [AttackProfile(minimumAttack: 15, maximumAttack: 15, epBlockCost: 200)])
        let defender = makeSnapshot(armor: [.rightHand: 2])

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.rightHand],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        // Then
        if case .critHit(let weaponDmg, let strengthDmg, let armor, let multiplier, _) = results[.rightHand] {
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
        let attacker = makeSnapshot(attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)])
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
        XCTAssertEqual(results[.body], .blocked(wasCrit: false, epSpent: 200))
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
        let attacker = makeSnapshot(attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)])
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

    // MARK: - EP / Endurance

    /// Pins the `guard blockCost > 0` semantic at the calculator level: when
    /// the endurance service returns a 0 cost (e.g., baseCost of 0 from a
    /// missing-data weapon), the block must fall through to an undefended
    /// resolution and consume no EP. Defends against accidental removal of
    /// the guard, which would crash on subsequent `defenderRemainingEP -= 0`
    /// loop iterations passing the check trivially.
    func testZeroBlockCost_BlockFallsThrough() async {
        // Given: endurance service yields zero cost for this strike.
        mockEnduranceService.costToReturn = 0
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 0
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [
            AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 0)
        ])
        let defender = makeSnapshot(currentEP: 1000) // plenty of EP — irrelevant

        // When: head is both attacked and defended.
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        // Then: must resolve as .hit (block didn't protect), zero EP consumed.
        if case .hit = results[.head] {
            // Expected
        } else {
            XCTFail("Expected .hit on zero-cost block fallthrough, got \(String(describing: results[.head]))")
        }
        XCTAssertEqual(results[.head]?.epSpentValue, 0, "Zero-cost block must not consume EP")
    }

    func testBlock_InsufficientEP_FallsThroughAndSpendsZero() async {
        // Given: cost 200, defender has only 100
        mockEnduranceService.costToReturn = 200
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)])
        let defender = makeSnapshot(currentEP: 100)

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        // Then: block accepted but doesn't protect → resolved as undefended hit, no EP spent.
        if case .hit(let weaponDmg, let strengthDmg, _) = results[.head] {
            XCTAssertEqual(weaponDmg, 10)
            XCTAssertEqual(strengthDmg, 5)
        } else {
            XCTFail("Expected hit fallthrough on insufficient EP, got \(String(describing: results[.head]))")
        }
        XCTAssertEqual(results[.head]?.epSpentValue, 0)
    }

    func testCritPiercesBlock_StillSpendsEP() async {
        // Given: cost 200, EP plenty, crit succeeds → block pierced.
        mockEnduranceService.costToReturn = 200
        mockCritService.shouldCrit = true
        mockCritService.critMultiplier = 2.0
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)])
        let defender = makeSnapshot(currentEP: GameMechanicsConstants.startingEP)

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        // Then: damage applies AND EP is consumed.
        if case .critHit(_, _, _, _, let epSpent) = results[.head] {
            XCTAssertEqual(epSpent, 200)
        } else {
            XCTFail("Expected critHit with EP spent, got \(String(describing: results[.head]))")
        }
    }

    func testMultipleBlocks_DrainEPSequentially() async {
        // Given: cost 200 per block, defender has 350 → can afford 1 block, second falls through.
        mockEnduranceService.costToReturn = 200
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 0
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [AttackProfile(minimumAttack: 5, maximumAttack: 5, epBlockCost: 200)])
        let defender = makeSnapshot(currentEP: 350)

        // When: two body parts attacked AND defended
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head, .body],
            defendingPoints: [.head, .body],
            attacker: attacker,
            defender: defender
        )

        // Then: total EP spent across both parts is exactly one block's cost (200).
        let totalEP = (results[.head]?.epSpentValue ?? 0) + (results[.body]?.epSpentValue ?? 0)
        XCTAssertEqual(totalEP, 200, "Only one block should fit in 350 EP at cost 200")
    }

    // MARK: - EP boundaries

    /// Pins the `defenderRemainingEP >= blockCost` semantics: when the defender
    /// has *exactly* the cost on hand, the block must succeed — not fall through.
    /// Guards against accidental `>` regressions.
    func testBlock_EPExactlyEqualsCost_BlockSucceeds() async {
        // Given
        mockEnduranceService.costToReturn = 200
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [
            AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)
        ])
        let defender = makeSnapshot(currentEP: 200) // exactly one block's worth

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        // Then
        XCTAssertEqual(
            results[.head],
            .blocked(wasCrit: false, epSpent: 200),
            "Block must succeed when EP exactly equals cost (boundary is `>=`)"
        )
    }

    /// EP is consumed only when the defender attempted to block. An undefended
    /// attack must leave EP untouched even if a profile specifies a cost.
    func testUndefendedAttack_DoesNotConsumeEP() async {
        // Given
        mockEnduranceService.costToReturn = 200
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [
            AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)
        ])
        let defender = makeSnapshot(currentEP: 1000)

        // When: head is attacked but NOT defended.
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        // Then: must resolve as .hit, not .blocked, with no EP spent.
        XCTAssertEqual(results[.head]?.epSpentValue, 0, "Undefended attack must not consume EP")
        if case .hit = results[.head] {
            // Expected
        } else {
            XCTFail("Expected .hit on undefended attack, got \(String(describing: results[.head]))")
        }
    }

    // MARK: - Dual-wield: per-strike profiles

    /// Strike 1 (right) consumes its weapon's EP cost; strike 2 (left) consumes
    /// the off-hand weapon's EP cost. Body-part iteration order in the
    /// calculator (`[.head, .body, .leftHand, .rightHand, .legs]`) maps strike
    /// index → body part.
    func testDualWield_StrikesUsePerWeaponEPCost() async {
        // Given: attacker has two strikes with different EP costs.
        // Endurance mock returns identity (cost = baseCost) so we read raw values.
        mockEnduranceService.costToReturn = nil   // identity passthrough
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [
            AttackProfile(minimumAttack: 1, maximumAttack: 1, epBlockCost: 100), // strike 1 = right
            AttackProfile(minimumAttack: 1, maximumAttack: 1, epBlockCost: 300)  // strike 2 = left
        ])
        let defender = makeSnapshot(currentEP: GameMechanicsConstants.startingEP)

        // When: defender blocks both head and body — both strikes land on
        // defended parts, so both consume their weapon-specific EP.
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head, .body],
            defendingPoints: [.head, .body],
            attacker: attacker,
            defender: defender
        )

        // Then: head (1st in iteration) → right weapon = 100 EP;
        //       body (2nd in iteration) → left weapon = 300 EP.
        XCTAssertEqual(results[.head]?.epSpentValue, 100, "Strike 1 must use right weapon's EP cost")
        XCTAssertEqual(results[.body]?.epSpentValue, 300, "Strike 2 must use left weapon's EP cost")
    }

    /// When EP is limited, the right (primary) weapon's strike drains EP
    /// before the left (secondary) — matches "primary checks first" design rule.
    func testDualWield_RightWeaponDrainsEPBeforeLeft() async {
        // Given: defender can only afford ONE 200-EP block. Both strikes cost 200.
        mockEnduranceService.costToReturn = nil   // identity passthrough
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [
            AttackProfile(minimumAttack: 1, maximumAttack: 1, epBlockCost: 200), // right
            AttackProfile(minimumAttack: 1, maximumAttack: 1, epBlockCost: 200)  // left
        ])
        let defender = makeSnapshot(currentEP: 250)

        // When: both attacked body parts are defended.
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head, .body],
            defendingPoints: [.head, .body],
            attacker: attacker,
            defender: defender
        )

        // Then: head (strike 0 = right) wins the block. body (strike 1 = left)
        // sees only 50 EP left, falls through to undefended hit.
        XCTAssertEqual(results[.head]?.epSpentValue, 200, "Right weapon's strike must drain EP first")
        XCTAssertEqual(results[.body]?.epSpentValue, 0, "Left weapon's strike falls through after EP is exhausted")
    }

    /// Strike 1 deals right weapon's damage; strike 2 deals left weapon's
    /// damage. Hits are unblocked, undodged, non-crit so the weapon damage
    /// shows up directly in the `.hit` payload.
    func testDualWield_StrikesUsePerWeaponDamage() async {
        // Given
        mockEnduranceService.costToReturn = nil
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 0
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [
            AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 0), // right
            AttackProfile(minimumAttack: 4, maximumAttack: 4, epBlockCost: 0)    // left
        ])
        let defender = makeSnapshot()

        // When: two body parts attacked, none defended
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head, .body],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        // Then: head (1st) gets weapon damage 10; body (2nd) gets 4.
        if case .hit(let weaponDmg, _, _) = results[.head] {
            XCTAssertEqual(weaponDmg, 10, "Strike 1 uses right weapon damage")
        } else {
            XCTFail("Expected .hit on head, got \(String(describing: results[.head]))")
        }
        if case .hit(let weaponDmg, _, _) = results[.body] {
            XCTAssertEqual(weaponDmg, 4, "Strike 2 uses left weapon damage")
        } else {
            XCTFail("Expected .hit on body, got \(String(describing: results[.body]))")
        }
    }
}

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
        nonisolated(unsafe) var enduranceReductionToReturn: Int16 = 0
        /// Captures the defender endurance value passed to
        /// `getRandomEnduranceDamageReduction` so tests can assert the
        /// calculator reads the **defender**'s stat (not the attacker's).
        nonisolated(unsafe) var lastEnduranceQueried: Int16?

        func getMinMaxStrengthDamage(_ strengthAttribute: Int16) -> (minDmg: Int16, maxDmg: Int16)? {
            return (0, strengthDamageToReturn)
        }

        func getStrengthDamageDistribution(_ strengthAttribute: Int16) -> (distribution: [Int16], weights: [Int]) {
            return ([strengthDamageToReturn], [1])
        }

        func getRandomStrengthDamage(_ strengthAttribute: Int16) -> Int16 {
            return strengthDamageToReturn
        }

        func getRandomEnduranceDamageReduction(_ enduranceAttribute: Int16) -> Int16 {
            lastEnduranceQueried = enduranceAttribute
            return enduranceReductionToReturn
        }

        func getWeaponDamage(weaponId: UUID?) -> (minDmg: Int16, maxDmg: Int16)? {
            return (weaponDamageToReturn, weaponDamageToReturn)
        }

        func getRandomWeaponDamage(weaponId: UUID?) -> Int16 {
            return weaponDamageToReturn
        }

        func calculateTotalDamage(from pointStatus: [BodyPart: PointStatus]) -> Int {
            // Delegate to the single source of truth — same as production
            // `ElfDamageService.calculateTotalDamage`. Keeps this mock from
            // re-deriving the formula and drifting from `PointStatus.damageTakenValue`.
            pointStatus.values.reduce(0) { $0 + $1.damageTakenValue }
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
        /// Deterministic value returned by `selectBlockedCritMultiplier()`.
        /// Defaults to 1.0 — matches the old "always 1.0" behavior so
        /// non-blocked-crit tests don't need to set anything.
        nonisolated(unsafe) var blockedCritMultiplier: Double = 1.0

        func calculateCrit(power: Int16, instinct: Int16) -> CritCalculationResult {
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
                multiplierRoll: shouldCrit ? 50 : nil,
                selectedMultiplier: shouldCrit ? critMultiplier : 1.0
            )
        }

        func selectBlockedCritMultiplier() -> Double {
            blockedCritMultiplier
        }
    }

    /// Passthrough BuffEffectsCalculator — no buffs altered, returns base
    /// attributes unchanged. Keeps combat tests independent of buff math.
    final class PassthroughBuffEffectsCalculator: BuffEffectsCalculator, @unchecked Sendable {
        func apply(buffs: [AppliedBuff], to base: HeroAttributes) -> HeroAttributes {
            base
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
        instinct: Int = 10,
        endurance: Int = 0,
        currentEP: Int = GameMechanicsConstants.startingEP,
        attacks: [AttackProfile] = [
            AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)
        ],
        armor: [BodyPart: Int] = [:],
        battleBuffs: [AppliedBuff] = []
    ) -> CombatantSnapshot {
        return CombatantSnapshot(
            id: UUID(),
            sourceId: UUID(),
            name: "Test",
            imageName: "",
            combatantType: .elf,
            currentHP: 100,
            currentMP: 0,
            currentEP: currentEP,
            maxEP: GameMechanicsConstants.startingEP,
            baseHeroAttributes: HeroAttributes(
                hitPoints: 100, manaPoints: 0,
                agility: Attribute(Int16(clamping: agility)),
                strength: Attribute(Int16(clamping: strength)),
                power: Attribute(Int16(clamping: power)),
                instinct: Attribute(Int16(clamping: instinct)),
                endurance: Attribute(Int16(clamping: endurance))
            ),
            attacks: attacks,
            defensePoints: 2,
            armorValues: armor,
            battleBuffs: battleBuffs
        )
    }

    private func exhaustedBattleBuff() -> AppliedBuff {
        AppliedBuff(buffId: BuffCatalogID.exhaustedBattle, stacks: 1)
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
            $0.buffEffectsCalculator = PassthroughBuffEffectsCalculator()
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
        let defender = makeSnapshot(instinct: 30)

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
        // Given: the rolled crit multiplier (2.0) would normally apply, but
        // block downgrades it to whatever `CritService.selectBlockedCritMultiplier`
        // returns. We pin the mock to 1.25 to verify the calculator uses the
        // service's rolled value, not the original `critResult.selectedMultiplier`.
        mockCritService.shouldCrit = true
        mockCritService.critMultiplier = 2.0
        mockCritService.blockedCritMultiplier = 1.25
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(power: 50, attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)])
        let defender = makeSnapshot(instinct: 10, armor: [.head: 3])

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        // Then: status remains `.critHit` for UI, but multiplier is whatever
        // the service rolled for blocked crits (here pinned to 1.25 via mock).
        if case .critHit(let weaponDmg, let strengthDmg, _, let armor, let multiplier, _) = results[.head] {
            XCTAssertEqual(weaponDmg, 10)
            XCTAssertEqual(strengthDmg, 5)
            XCTAssertEqual(armor, 3)
            XCTAssertEqual(multiplier, 1.25, "Calculator must use service-rolled blocked-crit multiplier, not raw critResult.selectedMultiplier")
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
        if case .hit(let weaponDmg, let strengthDmg, _, let armor) = results[.legs] {
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
        if case .critHit(let weaponDmg, let strengthDmg, _, let armor, let multiplier, _) = results[.rightHand] {
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
        if case .hit(let weaponDmg, let strengthDmg, _, let armor) = results[.head] {
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
        if case .hit(_, _, _, let armor) = results[.head] {
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
        if case .hit(_, _, _, let armor) = results[.body] {
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

    /// New: a defender with EP > 0 but less than `blockCost` still BLOCKS the
    /// strike. The remaining EP is drained to 0; the runner will apply
    /// `Exhausted` at end of round.
    func testBlock_InsufficientEP_DrainsRemainderAndStillBlocks() async {
        // Given: cost 200, defender has only 100
        mockEnduranceService.costToReturn = 200
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
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

        // Then: block held — defender pays the remaining 100 EP, takes no damage.
        XCTAssertEqual(results[.head], .blocked(wasCrit: false, epSpent: 100))
    }

    /// EP == 0 and the defender does NOT carry Exhausted (e.g. drained earlier
    /// this same round, before the end-of-round hook ran): the block has no
    /// resource to absorb anything, so the strike falls through to undefended.
    func testBlock_EPZero_WithoutExhausted_FallsThroughToUndefended() async {
        // Given
        mockEnduranceService.costToReturn = 200
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)])
        let defender = makeSnapshot(currentEP: 0)

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        // Then: resolved as a normal undefended hit, no EP spent.
        if case .hit(let weaponDmg, let strengthDmg, _, _) = results[.head] {
            XCTAssertEqual(weaponDmg, 10)
            XCTAssertEqual(strengthDmg, 5)
        } else {
            XCTFail("Expected hit fallthrough on EP=0 without Exhausted, got \(String(describing: results[.head]))")
        }
        XCTAssertEqual(results[.head]?.epSpentValue, 0)
    }

    /// EP == 0 and the defender carries `Exhausted` (applied by the round runner
    /// in a previous round) and the strike is NOT a crit: the strike is
    /// "weak-blocked" — full damage chain runs, then the post-armor total is
    /// multiplied by `exhaustedBlockDamageMultiplier` (`0.6`).
    func testBlock_EPZero_WithExhausted_NoCrit_AppliesPostArmorMultiplier() async {
        // Given: full chain would deal weapon 10 + str 6 − end 0 − armor 4 = 12;
        //        × 0.6 = 7.2 → floor → 7.
        mockEnduranceService.costToReturn = 200
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 6
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)])
        let defender = makeSnapshot(
            currentEP: 0,
            armor: [.head: 4],
            battleBuffs: [exhaustedBattleBuff()]
        )

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        // Then
        if case .weakBlocked(let weaponDmg, let strengthDmg, let endRed, let armor, let mult, let finalDamage, let wasCrit) = results[.head] {
            XCTAssertEqual(weaponDmg, 10)
            XCTAssertEqual(strengthDmg, 6)
            XCTAssertEqual(endRed, 0)
            XCTAssertEqual(armor, 4)
            XCTAssertEqual(mult, 1.0)
            XCTAssertFalse(wasCrit)
            XCTAssertEqual(finalDamage, 7, "10 + 6 − 0 − 4 = 12, × 0.6 = 7.2 → 7")
        } else {
            XCTFail("Expected weakBlocked, got \(String(describing: results[.head]))")
        }
        XCTAssertEqual(results[.head]?.epSpentValue, 0, "Weak block must not spend EP")
    }

    /// A crit landing on a weak block: the calculator must roll the
    /// **blocked-crit** multiplier distribution (mock pinned to `1.25`)
    /// instead of using the raw `selectedMultiplier`. The downgraded crit IS
    /// the entire penalty — `exhaustedBlockDamageMultiplier` does NOT apply
    /// on this branch (no double-dip).
    func testBlock_EPZero_WithExhausted_CritUsesBlockedMultiplierNotHalved() async {
        // Given: blocked-crit multiplier pinned to 1.25.
        //        weapon 10 × 1.25 = 12 (Int floor), + str 5 − end 0 − armor 2 = 15.
        //        No further halving by 0.6 — final = 15.
        mockEnduranceService.costToReturn = 200
        mockCritService.shouldCrit = true
        mockCritService.critMultiplier = 2.0          // raw multiplier — must be IGNORED on weak-block crit
        mockCritService.blockedCritMultiplier = 1.25  // value calculator must read instead
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)])
        let defender = makeSnapshot(
            currentEP: 0,
            armor: [.head: 2],
            battleBuffs: [exhaustedBattleBuff()]
        )

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        // Then
        if case .weakBlocked(_, _, _, _, let mult, let finalDamage, let wasCrit) = results[.head] {
            XCTAssertTrue(wasCrit)
            XCTAssertEqual(mult, 1.25, "Weak-block crit must use selectBlockedCritMultiplier(), not raw selectedMultiplier")
            XCTAssertEqual(finalDamage, 15, "Int(10×1.25) + 5 − 0 − 2 = 15; no extra ×0.6 on the crit branch")
        } else {
            XCTFail("Expected weakBlocked crit, got \(String(describing: results[.head]))")
        }
        XCTAssertEqual(results[.head]?.epSpentValue, 0, "Weak block must not spend EP")
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
        if case .critHit(_, _, _, _, _, let epSpent) = results[.head] {
            XCTAssertEqual(epSpent, 200)
        } else {
            XCTFail("Expected critHit with EP spent, got \(String(describing: results[.head]))")
        }
    }

    func testMultipleBlocks_DrainEPSequentially() async {
        // Given: cost 200 per block, defender has 350 → first block spends 200,
        // second block drains the remaining 150 and STILL holds (new behavior).
        // Total EP spent across both = 350 (fully drained).
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

        // Then: both blocks hold, second drains the remainder.
        XCTAssertEqual(results[.head], .blocked(wasCrit: false, epSpent: 200))
        XCTAssertEqual(results[.body], .blocked(wasCrit: false, epSpent: 150))
        let totalEP = (results[.head]?.epSpentValue ?? 0) + (results[.body]?.epSpentValue ?? 0)
        XCTAssertEqual(totalEP, 350, "Both blocks hold; second one drains EP to 0")
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

        // Then: head (strike 0 = right) takes the full 200-EP block. body
        // (strike 1 = left) sees only 50 EP left — under the new rule the
        // block still HOLDS, draining the remaining 50 EP.
        XCTAssertEqual(results[.head]?.epSpentValue, 200, "Right weapon's strike must drain EP first")
        XCTAssertEqual(results[.body]?.epSpentValue, 50, "Left weapon's strike drains the remaining 50 EP and still blocks")
        XCTAssertEqual(results[.body], .blocked(wasCrit: false, epSpent: 50))
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
        if case .hit(let weaponDmg, _, _, _) = results[.head] {
            XCTAssertEqual(weaponDmg, 10, "Strike 1 uses right weapon damage")
        } else {
            XCTFail("Expected .hit on head, got \(String(describing: results[.head]))")
        }
        if case .hit(let weaponDmg, _, _, _) = results[.body] {
            XCTAssertEqual(weaponDmg, 4, "Strike 2 uses left weapon damage")
        } else {
            XCTFail("Expected .hit on body, got \(String(describing: results[.body]))")
        }
    }

    // MARK: - Endurance Damage Reduction

    /// Pins the wiring: the calculator must read **defender's** endurance for
    /// the reduction roll (not the attacker's). Mirror of how Strength reads
    /// the attacker's stat. Captured via the mock's `lastEnduranceQueried`.
    func testHit_ReadsDefenderEnduranceForReduction() async {
        // Given: attacker has endurance 99 (must be ignored), defender has 36.
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 4
        mockDamageService.enduranceReductionToReturn = 3
        let calculator = makeCalculator()
        let attacker = makeSnapshot(
            strength: 20,
            endurance: 99,
            attacks: [AttackProfile(minimumAttack: 8, maximumAttack: 8, epBlockCost: 200)]
        )
        let defender = makeSnapshot(endurance: 36)

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        // Then
        XCTAssertEqual(
            mockDamageService.lastEnduranceQueried,
            36,
            "Reduction roll must consult defender's effective endurance, not attacker's"
        )
        if case .hit(let weaponDmg, let strengthDmg, let enduranceRed, _) = results[.head] {
            XCTAssertEqual(weaponDmg, 8)
            XCTAssertEqual(strengthDmg, 4)
            XCTAssertEqual(enduranceRed, 3, "Endurance reduction must be propagated into PointStatus.hit")
        } else {
            XCTFail("Expected .hit, got \(String(describing: results[.head]))")
        }
    }

    /// On a successful crit (undefended), the endurance reduction is recorded
    /// in the `.critHit` payload alongside Strength, ready for the multiplier
    /// to scale them together via `calculateTotalDamage`.
    func testCritHit_CarriesEnduranceReduction() async {
        // Given
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = true
        mockCritService.critMultiplier = 2.0
        mockDamageService.strengthDamageToReturn = 6
        mockDamageService.enduranceReductionToReturn = 2
        let calculator = makeCalculator()
        let attacker = makeSnapshot(
            power: 50,
            attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)]
        )
        let defender = makeSnapshot(endurance: 20)

        // When
        let results = calculator.calculatePointStatus(
            attackingPoints: [.body],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        // Then
        if case .critHit(let weaponDmg, let strengthDmg, let enduranceRed, _, let multiplier, _) = results[.body] {
            XCTAssertEqual(weaponDmg, 10)
            XCTAssertEqual(strengthDmg, 6)
            XCTAssertEqual(enduranceRed, 2)
            XCTAssertEqual(multiplier, 2.0)
        } else {
            XCTFail("Expected .critHit, got \(String(describing: results[.body]))")
        }
    }
}

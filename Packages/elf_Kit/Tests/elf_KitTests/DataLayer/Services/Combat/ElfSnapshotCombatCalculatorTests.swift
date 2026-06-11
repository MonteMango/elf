//
//  ElfSnapshotCombatCalculatorTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for `ElfSnapshotCombatCalculator`.
///
/// Combat logic:
/// - Attack on defended point: dodge → crit (amplifies block EP cost) → block resolution.
/// - Attack on undefended point: dodge → crit/normal hit.
/// - No attack on point: `.nothing`.
///
/// Blocked-crit damage is **not** downgraded anymore — it lands at the
/// full multiplier and pays an EP tax through
/// `GameMechanicsConstants.critEPCostBonusRatio`. The old
/// `selectBlockedCritMultiplier` API is removed.
final class ElfSnapshotCombatCalculatorTests: XCTestCase {

    // MARK: - Mock Services

    /// Mock Damage Service. Captures the defender endurance values fed to
    /// `getRandomDamageReduction(...)` so tests can assert the calculator
    /// reads the **defender**'s stats (not the attacker's).
    final class MockDamageService: DamageService, @unchecked Sendable {
        nonisolated(unsafe) var strengthDamageToReturn: Int16 = 5
        nonisolated(unsafe) var weaponDamageToReturn: Int16 = 10
        nonisolated(unsafe) var damageReductionToReturn: Int16 = 0
        /// Statuses captured on each reduction roll — `(stat, coefficient)`.
        /// The calculator rolls reduction twice per strike: once with
        /// `intuitionReductionCoefficient`, once with
        /// `enduranceReductionCoefficient`. Tests assert both invocations.
        nonisolated(unsafe) var reductionCalls: [(stat: Int16, coefficient: Double)] = []

        func getRandomStrengthDamage(_ strengthAttribute: Int16, using generator: WithRandomNumberGenerator) -> Int16 {
            strengthDamageToReturn
        }

        func getRandomDamageReduction(stat: Int16, coefficient: Double, using generator: WithRandomNumberGenerator) -> Int16 {
            reductionCalls.append((stat, coefficient))
            return damageReductionToReturn
        }

        func getWeaponDamage(weaponId: ItemID?) -> (minDmg: Int16, maxDmg: Int16)? {
            (weaponDamageToReturn, weaponDamageToReturn)
        }

        func calculateTotalDamage(from pointStatus: [BodyPart: PointStatus]) -> Int {
            pointStatus.values.reduce(0) { $0 + $1.damageTakenValue }
        }
    }

    /// Mock Dodge Service with controllable output.
    final class MockDodgeService: DodgeService, @unchecked Sendable {
        nonisolated(unsafe) var shouldDodge: Bool = false

        func calculateDodge(agility: Int16, instinct: Int16, attackerLevel: Int, using generator: WithRandomNumberGenerator) -> DodgeCalculationResult {
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

    /// Mock Endurance Service. Defaults to identity (returns `baseCost` unchanged)
    /// so tests not focused on EP need no setup.
    final class MockEnduranceService: EnduranceService, @unchecked Sendable {
        nonisolated(unsafe) var costToReturn: Int? = nil

        func calculateBlockCost(baseCost: Int, defenderEndurance: Int, attackerStrength: Int) -> Int {
            costToReturn ?? baseCost
        }
    }

    /// Mock Crit Service.
    final class MockCritService: CritService, @unchecked Sendable {
        nonisolated(unsafe) var shouldCrit: Bool = false
        nonisolated(unsafe) var critMultiplier: Double = 1.5

        func calculateCrit(power: Int16, instinct: Int16, attackerLevel: Int, using generator: WithRandomNumberGenerator) -> CritCalculationResult {
            let distribution = CritDistribution(
                minimumChance: 10,
                maximumChance: 50,
                rangeValues: [30],
                rangeWeights: [1]
            )
            return CritCalculationResult(
                distribution: distribution,
                selectedChance: 30,
                stage2Roll: shouldCrit ? 10 : 90,
                success: shouldCrit,
                selectedMultiplier: shouldCrit ? critMultiplier : 1.0
            )
        }
    }

    // Passthrough BuffEffectsCalculator lives in Helpers/ — shared with
    // DefaultCombatantSnapshotBuilderTests.

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
        CombatantSnapshot(
            id: CombatantID(),
            source: .synthetic,
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
            // The calculator's own weapon-damage roll; seeded for determinism.
            $0.withRandomNumberGenerator = WithRandomNumberGenerator(
                SeededRandomNumberGenerator(seed: 0xE1F)
            )
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
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot(power: 20)
        let defender = makeSnapshot(instinct: 30)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        XCTAssertEqual(results[.head], .blocked(epSpent: 200))
    }

    /// On the **successful-block path**, a crit no longer downgrades the
    /// multiplier — it lands at the full rolled multiplier and is paid for
    /// with an EP tax (`critEPCostBonusRatio`). This test pins the new
    /// behavior: status is `.critHit`, multiplier matches the rolled value,
    /// and the EP cost is amplified.
    func testBlock_CritAmplifiesEPCost_AndKeepsFullMultiplier() async {
        mockCritService.shouldCrit = true
        mockCritService.critMultiplier = 2.0
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(
            power: 50,
            attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)]
        )
        let defender = makeSnapshot(instinct: 10, armor: [.head: 3])

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        guard case let .critHit(weaponDmg, strengthDmg, _, armor, multiplier, epSpent) = results[.head] else {
            XCTFail("Expected critHit, got \(String(describing: results[.head]))")
            return
        }
        XCTAssertEqual(weaponDmg, 10)
        XCTAssertEqual(strengthDmg, 5)
        XCTAssertEqual(armor, 3)
        XCTAssertEqual(multiplier, 2.0,
                       "Blocked crit must use the full rolled multiplier — no downgrade")

        // EP tax formula (from resolveDefendedAttack):
        //   amplifiedBaseCost = round(baseCost × (1 + (mult − 1) × ratio))
        //   enduranceFlatReduction = baseCost − blockCost (here: 0, identity mock)
        //   actualBlockCost = max(1, amplifiedBaseCost − enduranceFlatReduction)
        let ratio = GameMechanicsConstants.critEPCostBonusRatio
        let amplifiedBaseCost = Int((200.0 * (1.0 + (2.0 - 1.0) * ratio)).rounded())
        XCTAssertEqual(epSpent, amplifiedBaseCost,
                       "Blocked crit must amplify EP cost via critEPCostBonusRatio")
    }

    // MARK: - Case 2: Attack on Undefended Point

    func testAttackOnUndefendedPoint_Dodged_ResultsInDodge() async {
        mockDodgeService.shouldDodge = true
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot()
        let defender = makeSnapshot(agility: 50)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.body],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        XCTAssertEqual(results[.body], .dodged(wasCrit: false))
    }

    func testAttackOnUndefendedPoint_DodgedWithCrit_ResultsInDodgeWithCritFlag() async {
        mockDodgeService.shouldDodge = true
        mockCritService.shouldCrit = true
        let calculator = makeCalculator()
        let attacker = makeSnapshot(power: 80)
        let defender = makeSnapshot(agility: 50)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.body],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        XCTAssertEqual(results[.body], .dodged(wasCrit: true))
    }

    func testAttackOnUndefendedPoint_NotDodged_NoCrit_ResultsInNormalHit() async {
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 6
        let calculator = makeCalculator()
        let attacker = makeSnapshot(
            strength: 20,
            attacks: [AttackProfile(minimumAttack: 12, maximumAttack: 12, epBlockCost: 200)]
        )
        let defender = makeSnapshot(armor: [.legs: 5])

        let results = calculator.calculatePointStatus(
            attackingPoints: [.legs],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        guard case let .hit(weaponDmg, strengthDmg, _, armor) = results[.legs] else {
            XCTFail("Expected hit, got \(String(describing: results[.legs]))")
            return
        }
        XCTAssertEqual(weaponDmg, 12)
        XCTAssertEqual(strengthDmg, 6)
        XCTAssertEqual(armor, 5)
    }

    func testAttackOnUndefendedPoint_NotDodged_WithCrit_ResultsInCritHit() async {
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = true
        mockCritService.critMultiplier = 1.5
        mockDamageService.strengthDamageToReturn = 8
        let calculator = makeCalculator()
        let attacker = makeSnapshot(
            power: 60,
            attacks: [AttackProfile(minimumAttack: 15, maximumAttack: 15, epBlockCost: 200)]
        )
        let defender = makeSnapshot(armor: [.rightHand: 2])

        let results = calculator.calculatePointStatus(
            attackingPoints: [.rightHand],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        guard case let .critHit(weaponDmg, strengthDmg, _, armor, multiplier, _) = results[.rightHand] else {
            XCTFail("Expected critHit, got \(String(describing: results[.rightHand]))")
            return
        }
        XCTAssertEqual(weaponDmg, 15)
        XCTAssertEqual(strengthDmg, 8)
        XCTAssertEqual(armor, 2)
        XCTAssertEqual(multiplier, 1.5)
    }

    // MARK: - Case 3: No Attack on Point

    func testNoAttackOnPoint_ResultsInNothing() async {
        let calculator = makeCalculator()
        let attacker = makeSnapshot()
        let defender = makeSnapshot()

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.body],
            attacker: attacker,
            defender: defender
        )

        XCTAssertEqual(results[.body], .nothing)
        XCTAssertEqual(results[.legs], .nothing)
        XCTAssertEqual(results[.leftHand], .nothing)
        XCTAssertEqual(results[.rightHand], .nothing)
    }

    // MARK: - Multiple Attack Points

    func testMultipleAttackPoints_EachProcessedIndependently() async {
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(
            attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)]
        )
        let defender = makeSnapshot(armor: [.head: 2, .body: 3])

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head, .body],
            defendingPoints: [.body],
            attacker: attacker,
            defender: defender
        )

        guard case let .hit(weaponDmg, strengthDmg, _, armor) = results[.head] else {
            XCTFail("Expected hit for head")
            return
        }
        XCTAssertEqual(weaponDmg, 10)
        XCTAssertEqual(strengthDmg, 5)
        XCTAssertEqual(armor, 2)

        XCTAssertEqual(results[.body], .blocked(epSpent: 200))
    }

    // MARK: - All Body Parts Covered

    func testAllBodyPartsReturnResults() async {
        let calculator = makeCalculator()
        let attacker = makeSnapshot()
        let defender = makeSnapshot()

        let results = calculator.calculatePointStatus(
            attackingPoints: [],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        XCTAssertNotNil(results[.head])
        XCTAssertNotNil(results[.body])
        XCTAssertNotNil(results[.leftHand])
        XCTAssertNotNil(results[.rightHand])
        XCTAssertNotNil(results[.legs])
        XCTAssertEqual(results.count, 5)
    }

    // MARK: - Armor Application

    func testArmorIsAppliedFromDefender() async {
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(
            attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)]
        )
        let defender = makeSnapshot(armor: [.head: 8])

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        guard case let .hit(_, _, _, armor) = results[.head] else {
            XCTFail("Expected hit")
            return
        }
        XCTAssertEqual(armor, 8)
    }

    func testZeroArmorWhenNotSpecified() async {
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot()
        let defender = makeSnapshot(armor: [:])

        let results = calculator.calculatePointStatus(
            attackingPoints: [.body],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        guard case let .hit(_, _, _, armor) = results[.body] else {
            XCTFail("Expected hit")
            return
        }
        XCTAssertEqual(armor, 0)
    }

    // MARK: - EP / Endurance

    /// Pins the `guard blockCost > 0` semantic at the calculator level. When
    /// endurance returns 0 cost (e.g., baseCost of 0 from a missing-data
    /// weapon), the block must fall through to an undefended resolution and
    /// consume no EP.
    func testZeroBlockCost_BlockFallsThrough() async {
        mockEnduranceService.costToReturn = 0
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 0
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [
            AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 0)
        ])
        let defender = makeSnapshot(currentEP: 1000)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        if case .hit = results[.head] {
        } else {
            XCTFail("Expected .hit on zero-cost block fallthrough, got \(String(describing: results[.head]))")
        }
        XCTAssertEqual(results[.head]?.epSpentValue, 0)
    }

    /// A defender with EP > 0 but less than `blockCost` still BLOCKS the
    /// strike. Remaining EP is drained to 0; the runner will apply
    /// `Exhausted` at end of round.
    func testBlock_InsufficientEP_DrainsRemainderAndStillBlocks() async {
        mockEnduranceService.costToReturn = 200
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)])
        let defender = makeSnapshot(currentEP: 100)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        XCTAssertEqual(results[.head], .blocked(epSpent: 100))
    }

    /// EP == 0 and the defender does NOT carry Exhausted: block has no
    /// resource to absorb anything → falls through to undefended.
    func testBlock_EPZero_WithoutExhausted_FallsThroughToUndefended() async {
        mockEnduranceService.costToReturn = 200
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)])
        let defender = makeSnapshot(currentEP: 0)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        guard case let .hit(weaponDmg, strengthDmg, _, _) = results[.head] else {
            XCTFail("Expected hit fallthrough, got \(String(describing: results[.head]))")
            return
        }
        XCTAssertEqual(weaponDmg, 10)
        XCTAssertEqual(strengthDmg, 5)
        XCTAssertEqual(results[.head]?.epSpentValue, 0)
    }

    /// EP == 0 with Exhausted defender, NO crit: full damage chain runs,
    /// then post-armor total × `exhaustedBlockDamageMultiplier` (`0.6`).
    func testBlock_EPZero_WithExhausted_NoCrit_AppliesPostArmorMultiplier() async {
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

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        guard case let .weakBlocked(weaponDmg, strengthDmg, endRed, armor, mult, finalDamage, wasCrit) = results[.head] else {
            XCTFail("Expected weakBlocked, got \(String(describing: results[.head]))")
            return
        }
        XCTAssertEqual(weaponDmg, 10)
        XCTAssertEqual(strengthDmg, 6)
        XCTAssertEqual(endRed, 0)
        XCTAssertEqual(armor, 4)
        XCTAssertEqual(mult, 1.0)
        XCTAssertFalse(wasCrit)
        XCTAssertEqual(finalDamage, 7, "10 + 6 − 0 − 4 = 12, × 0.6 = 7.2 → 7")
        XCTAssertEqual(results[.head]?.epSpentValue, 0)
    }

    /// A crit landing on a weak block: the crit lands at the **full**
    /// rolled multiplier (no blocked-crit downgrade anymore) and the
    /// `exhaustedBlockDamageMultiplier` does NOT apply on the crit branch
    /// (no double-dip with weak-block).
    func testBlock_EPZero_WithExhausted_Crit_UsesFullMultiplierNoExtraHalving() async {
        mockEnduranceService.costToReturn = 200
        mockCritService.shouldCrit = true
        mockCritService.critMultiplier = 2.0
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)])
        let defender = makeSnapshot(
            currentEP: 0,
            armor: [.head: 2],
            battleBuffs: [exhaustedBattleBuff()]
        )

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        guard case let .weakBlocked(_, _, _, _, mult, finalDamage, wasCrit) = results[.head] else {
            XCTFail("Expected weakBlocked crit, got \(String(describing: results[.head]))")
            return
        }
        XCTAssertTrue(wasCrit)
        XCTAssertEqual(mult, 2.0, "Weak-block crit must use the full rolled multiplier — no downgrade")
        // Int(10 × 2.0) + 5 − 0 − 2 = 23; no extra ×0.6 on the crit branch.
        XCTAssertEqual(finalDamage, 23)
        XCTAssertEqual(results[.head]?.epSpentValue, 0, "Weak block must not spend EP")
    }

    func testCritPiercesBlock_StillSpendsEP() async {
        mockEnduranceService.costToReturn = 200
        mockCritService.shouldCrit = true
        mockCritService.critMultiplier = 2.0
        mockDamageService.strengthDamageToReturn = 5
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)])
        let defender = makeSnapshot(currentEP: GameMechanicsConstants.startingEP)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        guard case let .critHit(_, _, _, _, _, epSpent) = results[.head] else {
            XCTFail("Expected critHit with EP spent, got \(String(describing: results[.head]))")
            return
        }
        // Amplified by critEPCostBonusRatio: round(200 × (1 + 1.0 × 1.0)) = 400.
        let ratio = GameMechanicsConstants.critEPCostBonusRatio
        let amplified = Int((200.0 * (1.0 + (2.0 - 1.0) * ratio)).rounded())
        XCTAssertEqual(epSpent, amplified)
    }

    func testMultipleBlocks_DrainEPSequentially() async {
        mockEnduranceService.costToReturn = 200
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 0
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [AttackProfile(minimumAttack: 5, maximumAttack: 5, epBlockCost: 200)])
        let defender = makeSnapshot(currentEP: 350)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head, .body],
            defendingPoints: [.head, .body],
            attacker: attacker,
            defender: defender
        )

        XCTAssertEqual(results[.head], .blocked(epSpent: 200))
        XCTAssertEqual(results[.body], .blocked(epSpent: 150))
        let totalEP = (results[.head]?.epSpentValue ?? 0) + (results[.body]?.epSpentValue ?? 0)
        XCTAssertEqual(totalEP, 350, "Both blocks hold; second one drains EP to 0")
    }

    // MARK: - EP boundaries

    func testBlock_EPExactlyEqualsCost_BlockSucceeds() async {
        mockEnduranceService.costToReturn = 200
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [
            AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)
        ])
        let defender = makeSnapshot(currentEP: 200)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [.head],
            attacker: attacker,
            defender: defender
        )

        XCTAssertEqual(results[.head], .blocked(epSpent: 200))
    }

    func testUndefendedAttack_DoesNotConsumeEP() async {
        mockEnduranceService.costToReturn = 200
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [
            AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)
        ])
        let defender = makeSnapshot(currentEP: 1000)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        XCTAssertEqual(results[.head]?.epSpentValue, 0)
        if case .hit = results[.head] {
        } else {
            XCTFail("Expected .hit on undefended attack, got \(String(describing: results[.head]))")
        }
    }

    // MARK: - Dual-wield: per-strike profiles

    func testDualWield_StrikesUsePerWeaponEPCost() async {
        mockEnduranceService.costToReturn = nil
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [
            AttackProfile(minimumAttack: 1, maximumAttack: 1, epBlockCost: 100),
            AttackProfile(minimumAttack: 1, maximumAttack: 1, epBlockCost: 300)
        ])
        let defender = makeSnapshot(currentEP: GameMechanicsConstants.startingEP)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head, .body],
            defendingPoints: [.head, .body],
            attacker: attacker,
            defender: defender
        )

        XCTAssertEqual(results[.head]?.epSpentValue, 100)
        XCTAssertEqual(results[.body]?.epSpentValue, 300)
    }

    func testDualWield_RightWeaponDrainsEPBeforeLeft() async {
        mockEnduranceService.costToReturn = nil
        mockCritService.shouldCrit = false
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [
            AttackProfile(minimumAttack: 1, maximumAttack: 1, epBlockCost: 200),
            AttackProfile(minimumAttack: 1, maximumAttack: 1, epBlockCost: 200)
        ])
        let defender = makeSnapshot(currentEP: 250)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head, .body],
            defendingPoints: [.head, .body],
            attacker: attacker,
            defender: defender
        )

        XCTAssertEqual(results[.head]?.epSpentValue, 200)
        XCTAssertEqual(results[.body]?.epSpentValue, 50)
        XCTAssertEqual(results[.body], .blocked(epSpent: 50))
    }

    func testDualWield_StrikesUsePerWeaponDamage() async {
        mockEnduranceService.costToReturn = nil
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 0
        let calculator = makeCalculator()
        let attacker = makeSnapshot(attacks: [
            AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 0),
            AttackProfile(minimumAttack: 4, maximumAttack: 4, epBlockCost: 0)
        ])
        let defender = makeSnapshot()

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head, .body],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        if case let .hit(weaponDmg, _, _, _) = results[.head] {
            XCTAssertEqual(weaponDmg, 10)
        } else {
            XCTFail("Expected .hit on head, got \(String(describing: results[.head]))")
        }
        if case let .hit(weaponDmg, _, _, _) = results[.body] {
            XCTAssertEqual(weaponDmg, 4)
        } else {
            XCTFail("Expected .hit on body, got \(String(describing: results[.body]))")
        }
    }

    // MARK: - Damage Reduction Wiring

    /// Pins the wiring: the calculator must read **defender's** intuition AND
    /// endurance for the reduction roll, and pass each with the right
    /// coefficient. Each strike triggers exactly two reduction calls.
    func testHit_ReadsDefenderStatsForReduction() async {
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = false
        mockDamageService.strengthDamageToReturn = 4
        mockDamageService.damageReductionToReturn = 3
        let calculator = makeCalculator()
        let attacker = makeSnapshot(
            strength: 20,
            instinct: 99,   // must be ignored
            endurance: 99,  // must be ignored
            attacks: [AttackProfile(minimumAttack: 8, maximumAttack: 8, epBlockCost: 200)]
        )
        let defender = makeSnapshot(instinct: 22, endurance: 36)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.head],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        XCTAssertEqual(mockDamageService.reductionCalls.count, 2,
                       "Calculator must roll defender intuition and endurance reduction separately")
        let intuitionCall = mockDamageService.reductionCalls.first { $0.coefficient == GameMechanicsConstants.intuitionReductionCoefficient }
        let enduranceCall = mockDamageService.reductionCalls.first { $0.coefficient == GameMechanicsConstants.enduranceReductionCoefficient }
        XCTAssertEqual(intuitionCall?.stat, 22, "Intuition roll must read defender's intuition")
        XCTAssertEqual(enduranceCall?.stat, 36, "Endurance roll must read defender's endurance")

        guard case let .hit(weaponDmg, strengthDmg, enduranceRed, _) = results[.head] else {
            XCTFail("Expected .hit, got \(String(describing: results[.head]))")
            return
        }
        XCTAssertEqual(weaponDmg, 8)
        XCTAssertEqual(strengthDmg, 4)
        // Both rolls return 3; sum carried into payload.
        XCTAssertEqual(enduranceRed, 6, "Reduction payload must sum INT + END rolls")
    }

    /// On a successful crit (undefended), the reduction is recorded in
    /// `.critHit` alongside Strength so `calculateTotalDamage` can apply the
    /// multiplier only to weapon damage.
    func testCritHit_CarriesEnduranceReduction() async {
        mockDodgeService.shouldDodge = false
        mockCritService.shouldCrit = true
        mockCritService.critMultiplier = 2.0
        mockDamageService.strengthDamageToReturn = 6
        mockDamageService.damageReductionToReturn = 2
        let calculator = makeCalculator()
        let attacker = makeSnapshot(
            power: 50,
            attacks: [AttackProfile(minimumAttack: 10, maximumAttack: 10, epBlockCost: 200)]
        )
        let defender = makeSnapshot(endurance: 20)

        let results = calculator.calculatePointStatus(
            attackingPoints: [.body],
            defendingPoints: [],
            attacker: attacker,
            defender: defender
        )

        guard case let .critHit(weaponDmg, strengthDmg, enduranceRed, _, multiplier, _) = results[.body] else {
            XCTFail("Expected .critHit, got \(String(describing: results[.body]))")
            return
        }
        XCTAssertEqual(weaponDmg, 10)
        XCTAssertEqual(strengthDmg, 6)
        // Two reduction calls, each returning 2 → sum 4.
        XCTAssertEqual(enduranceRed, 4)
        XCTAssertEqual(multiplier, 2.0)
    }
}

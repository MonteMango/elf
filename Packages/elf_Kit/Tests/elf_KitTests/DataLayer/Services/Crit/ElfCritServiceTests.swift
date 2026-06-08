//
//  ElfCritServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for `ElfCritService`.
///
/// **Algorithm**:
/// - Stage 1: Select crit chance from the peak+linear-tail distribution.
/// - Stage 2: Check crit success (roll 1-100, succeed if roll ≤ chance).
/// - Stage 3: Select damage multiplier from the fixed multiplier distribution.
///
/// `selectBlockedCritMultiplier` is **removed** — blocked crits now use the
/// same multiplier distribution and pay an EP tax via
/// `GameMechanicsConstants.critEPCostBonusRatio` (asserted in
/// `ElfSnapshotCombatCalculatorTests.testBlock_CritAmplifiesEPCost`).
final class ElfCritServiceTests: XCTestCase {

    /// Level at which `min = power − instinct` semantics roughly hold. At L=0
    /// the multiplier collapses to the base (`0.8`), so a literal min from
    /// `power − instinct` is **not** correct — use `expectedSuppression(...)`.
    private static let testLevel: Int = 0

    private static func expectedSuppression(instinct: Int16, level: Int = ElfCritServiceTests.testLevel) -> Int16 {
        let mult = PeakLinearTailDistribution.multiplier(
            base: GameMechanicsConstants.critIntuitionSuppressionBaseMultiplier,
            perLevel: GameMechanicsConstants.critIntuitionSuppressionPerLevelDelta,
            attackerLevel: level
        )
        return Int16((Double(instinct) * mult).rounded())
    }

    /// Seeds the generator so `calculateCrit`'s convenience overload (which
    /// resolves `\.withRandomNumberGenerator` at call time) is deterministic.
    /// The inner scope wires the distribution + sampling/chance services the
    /// service-under-test pulls; kept nested so the seed is already current
    /// when those are resolved.
    override func invokeTest() {
        withDependencies {
            $0.withRandomNumberGenerator = WithRandomNumberGenerator(
                SeededRandomNumberGenerator(seed: 0xE1F)
            )
        } operation: {
            withDependencies {
                $0.critDistributionStrategy = ElfCritDistributionStrategy()
                $0.critMultiplierDistribution = CritMultiplierDistribution()
                $0.weightedSamplingService = ElfWeightedSamplingService()
                $0.chanceRollService = ElfChanceRollService()
            } operation: {
                super.invokeTest()
            }
        }
    }

    private func makeService() -> ElfCritService {
        ElfCritService()
    }

    // MARK: - Stage 1: Distribution Selection Tests

    func testStage1_SelectedChanceWithinDistributionRange() async {
        let service = makeService()
        let expectedMin = Int16(30) - Self.expectedSuppression(instinct: 10)
        for _ in 0..<100 {
            let result = service.calculateCrit(power: 30, instinct: 10, attackerLevel: Self.testLevel)
            XCTAssertGreaterThanOrEqual(result.selectedChance, expectedMin)
            XCTAssertLessThanOrEqual(result.selectedChance, 30)
        }
    }

    func testStage1_NegativeMinimumDistribution() async {
        let service = makeService()
        let result = service.calculateCrit(power: 5, instinct: 15, attackerLevel: Self.testLevel)
        let expectedMin = Int16(5) - Self.expectedSuppression(instinct: 15)
        XCTAssertGreaterThanOrEqual(result.selectedChance, expectedMin)
        XCTAssertLessThanOrEqual(result.selectedChance, 5)
    }

    // MARK: - Stage 2: Success Check Tests

    func testStage2_NegativeChance_AlwaysFails() async {
        let service = makeService()
        var autoFailCount = 0
        for _ in 0..<200 {
            let result = service.calculateCrit(power: 5, instinct: 20, attackerLevel: Self.testLevel)
            if result.selectedChance <= 0 {
                XCTAssertFalse(result.success, "Negative or zero chance should always fail")
                XCTAssertNil(result.stage2Roll)
                autoFailCount += 1
            }
        }
        XCTAssertGreaterThan(autoFailCount, 0, "Should have some auto-fail cases")
    }

    func testStage2_100PlusChance_AlwaysSucceeds() async {
        let service = makeService()
        let result = service.calculateCrit(power: 150, instinct: 10, attackerLevel: Self.testLevel)
        XCTAssertTrue(result.success)
        XCTAssertNil(result.stage2Roll)
        XCTAssertGreaterThanOrEqual(result.selectedChance, 100)
    }

    func testStage2_NormalRoll_RollIsBetween1And100() async {
        let service = makeService()
        var normalRollFound = false
        for _ in 0..<100 {
            let result = service.calculateCrit(power: 50, instinct: 10, attackerLevel: Self.testLevel)
            if let roll = result.stage2Roll {
                XCTAssertGreaterThanOrEqual(roll, 1)
                XCTAssertLessThanOrEqual(roll, 100)
                normalRollFound = true
            }
        }
        XCTAssertTrue(normalRollFound, "Should have at least one normal roll")
    }

    // MARK: - Stage 3: Multiplier Selection Tests

    func testStage3_CritFailed_MultiplierIs1() async {
        let service = makeService()
        var failedCritFound = false
        for _ in 0..<100 {
            let result = service.calculateCrit(power: 10, instinct: 20, attackerLevel: Self.testLevel)
            if !result.success {
                XCTAssertEqual(result.selectedMultiplier, 1.0)
                failedCritFound = true
                break
            }
        }
        XCTAssertTrue(failedCritFound, "Should find at least one failed crit")
    }

    func testStage3_CritSucceeded_MultiplierIsValid() async {
        let service = makeService()
        let validMultipliers: Set<Double> = Set(GameMechanicsConstants.critMultiplierValues)

        var successfulCritFound = false
        for _ in 0..<100 {
            let result = service.calculateCrit(power: 80, instinct: 10, attackerLevel: Self.testLevel)
            if result.success {
                XCTAssertTrue(validMultipliers.contains(result.selectedMultiplier),
                              "Multiplier \(result.selectedMultiplier) should be in valid set")
                successfulCritFound = true
                break
            }
        }
        XCTAssertTrue(successfulCritFound, "Should find at least one successful crit")
    }

    // MARK: - Result Structure Tests

    func testResultStructure_ContainsAllFields() async {
        let service = makeService()
        let result = service.calculateCrit(power: 40, instinct: 15, attackerLevel: Self.testLevel)

        XCTAssertNotNil(result.distribution)
        XCTAssertTrue(result.distribution.hasRange)
        XCTAssertGreaterThanOrEqual(result.selectedChance, result.distribution.minimumChance)
        XCTAssertLessThanOrEqual(result.selectedChance, result.distribution.maximumChance)
    }

    // MARK: - Statistical Tests

    func testStatistical_CritSuccessRate_CorrelatesWithPower() async {
        let service = makeService()
        let iterations = 500

        var lowPowerSuccesses = 0
        var highPowerSuccesses = 0
        for _ in 0..<iterations {
            let lowResult = service.calculateCrit(power: 20, instinct: 15, attackerLevel: Self.testLevel)
            let highResult = service.calculateCrit(power: 60, instinct: 15, attackerLevel: Self.testLevel)
            if lowResult.success { lowPowerSuccesses += 1 }
            if highResult.success { highPowerSuccesses += 1 }
        }
        XCTAssertGreaterThan(highPowerSuccesses, lowPowerSuccesses,
                             "Higher power should result in more crit successes")
    }

    func testStatistical_MultiplierVariety() async {
        let service = makeService()
        var multipliersFound: Set<Double> = []
        for _ in 0..<1000 {
            let result = service.calculateCrit(power: 80, instinct: 10, attackerLevel: Self.testLevel)
            if result.success {
                multipliersFound.insert(result.selectedMultiplier)
            }
        }
        XCTAssertGreaterThan(multipliersFound.count, 1)
    }

    // MARK: - Edge Cases

    func testEdgeCase_ZeroPower() async {
        let service = makeService()
        let result = service.calculateCrit(power: 0, instinct: 10, attackerLevel: Self.testLevel)
        let expectedMin = Int16(0) - Self.expectedSuppression(instinct: 10)
        XCTAssertEqual(result.distribution.minimumChance, expectedMin)
        XCTAssertEqual(result.distribution.maximumChance, 0)
        XCTAssertFalse(result.success, "Zero or negative power should always fail crit")
    }

    func testEdgeCase_ZeroInstinct() async {
        let service = makeService()
        let result = service.calculateCrit(power: 50, instinct: 0, attackerLevel: Self.testLevel)
        XCTAssertEqual(result.distribution.minimumChance, 50)
        XCTAssertEqual(result.distribution.maximumChance, 50)
        XCTAssertEqual(result.selectedChance, 50)
    }

    func testEdgeCase_AllZeros() async {
        let service = makeService()
        let result = service.calculateCrit(power: 0, instinct: 0, attackerLevel: Self.testLevel)
        XCTAssertEqual(result.distribution.minimumChance, 0)
        XCTAssertEqual(result.distribution.maximumChance, 0)
        XCTAssertFalse(result.success)
    }

    func testEdgeCase_VeryHighValues() async {
        let service = makeService()
        let result = service.calculateCrit(power: 200, instinct: 50, attackerLevel: Self.testLevel)
        let expectedMin = Int16(200) - Self.expectedSuppression(instinct: 50)
        XCTAssertEqual(result.distribution.maximumChance, 100, "Maximum capped at 100")
        XCTAssertEqual(result.distribution.minimumChance, expectedMin)
        XCTAssertTrue(result.success, "100+ chance should always succeed")
    }

    // MARK: - Crit-multiplier distribution mean

    /// Pins the canonical mean of `critMultiplierWeights` so a future tuning
    /// pass doesn't silently inflate or deflate crit damage. Mean is
    /// computed as `Σ (value × weight) / Σ weight` on the constant arrays
    /// — no RNG, so the assertion is deterministic.
    func testCritMultiplierDistribution_MeanMatchesWeightedExpectation() async {
        let values = GameMechanicsConstants.critMultiplierValues
        let weights = GameMechanicsConstants.critMultiplierWeights
        XCTAssertEqual(values.count, weights.count, "values/weights length mismatch")

        let totalWeight = weights.reduce(0, +)
        XCTAssertGreaterThan(totalWeight, 0)

        let weightedSum = zip(values, weights).reduce(0.0) { $0 + $1.0 * Double($1.1) }
        let mean = weightedSum / Double(totalWeight)
        // Current weights [0, 10, 25, 35, 20, 10] paired with
        // [0.75, 1.00, 1.25, 1.5, 2.0, 3.0] → mean ≈ 1.6375×.
        XCTAssertEqual(mean, 1.6375, accuracy: 0.001,
                       "Crit multiplier mean drift — confirm balance intent before changing weights")
    }
}

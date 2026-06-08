//
//  ElfDodgeServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for ElfDodgeService and ElfDodgeDistributionStrategy.
///
/// Suppression of dodge by attacker's intuition is level-scaled:
/// `mult = dodgeIntuitionSuppressionBaseMultiplier + dodgeIntuitionSuppressionPerLevelDelta × attackerLevel`.
/// Tests pin `attackerLevel = Self.testLevel`; that level is picked so the
/// multiplier comes out to exactly 1.0, keeping the legacy
/// `min = agility − instinct` arithmetic readable. If the constants are
/// re-tuned so 1.0 no longer falls on an integer level, tests must use
/// `expectedSuppression(...)`.
final class ElfDodgeServiceTests: XCTestCase {

    /// Level at which `base + perLevel × L == 1.0` for the current constants
    /// (0.8 + 0.04 × 5 = 1.0). All literal `min = agility − instinct`
    /// assertions below rely on this.
    private static let testLevel: Int = 5

    private static func expectedSuppression(instinct: Int16, level: Int = ElfDodgeServiceTests.testLevel) -> Int16 {
        let mult = PeakLinearTailDistribution.multiplier(
            base: GameMechanicsConstants.dodgeIntuitionSuppressionBaseMultiplier,
            perLevel: GameMechanicsConstants.dodgeIntuitionSuppressionPerLevelDelta,
            attackerLevel: level
        )
        return Int16((Double(instinct) * mult).rounded())
    }

    private func expectedPeakIndex(rangeSize: Int) -> Int {
        Int(round(GameMechanicsConstants.dodgePeakPosition * Double(rangeSize - 1)))
    }

    private let peakShareTolerance: Double = 0.05

    private func assertPeakDominates(_ weights: [Int], peakIndex: Int, file: StaticString = #file, line: UInt = #line) {
        let totalSum = weights.reduce(0, +)
        guard totalSum > 0 else {
            XCTFail("Weights sum must be positive", file: file, line: line)
            return
        }
        let actualShare = Double(weights[peakIndex]) / Double(totalSum)
        XCTAssertEqual(
            actualShare,
            GameMechanicsConstants.dodgePeakWeight,
            accuracy: peakShareTolerance,
            "Peak should claim ≈ \(GameMechanicsConstants.dodgePeakWeight) of total mass",
            file: file, line: line
        )
        for i in stride(from: peakIndex - 1, through: 0, by: -1) where i + 1 != peakIndex {
            XCTAssertLessThanOrEqual(weights[i], weights[i + 1], "Left tail must not grow toward edges", file: file, line: line)
        }
        for i in (peakIndex + 1)..<weights.count where i - 1 != peakIndex {
            XCTAssertLessThanOrEqual(weights[i], weights[i - 1], "Right tail must not grow toward edges", file: file, line: line)
        }
    }

    /// Asserts the test level still yields a multiplier of exactly 1.0. If
    /// a tuning pass breaks this invariant, all literal-min tests below need
    /// to switch to `expectedSuppression`.
    func testLevelInvariant_TestLevelProducesUnitMultiplier() {
        let mult = PeakLinearTailDistribution.multiplier(
            base: GameMechanicsConstants.dodgeIntuitionSuppressionBaseMultiplier,
            perLevel: GameMechanicsConstants.dodgeIntuitionSuppressionPerLevelDelta,
            attackerLevel: Self.testLevel
        )
        XCTAssertEqual(mult, 1.0, accuracy: 1e-9,
                       "Self.testLevel must yield multiplier 1.0 — re-tune constants or update tests")
    }

    /// Seeds the generator so `calculateDodge`'s convenience overload (which
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
                $0.dodgeDistributionStrategy = ElfDodgeDistributionStrategy()
                $0.weightedSamplingService = ElfWeightedSamplingService()
                $0.chanceRollService = ElfChanceRollService()
            } operation: {
                super.invokeTest()
            }
        }
    }

    // MARK: - Distribution Strategy Tests

    func testDistribution_StandardCase_22Agility10Instinct() async {
        let strategy = ElfDodgeDistributionStrategy()
        let distribution = strategy.distribution(agility: 22, instinct: 10, attackerLevel: Self.testLevel)

        XCTAssertEqual(distribution.minimumChance, 12)
        XCTAssertEqual(distribution.maximumChance, 22)
        XCTAssertEqual(distribution.rangeValues.count, 11)
        XCTAssertEqual(distribution.rangeValues.first, 12)
        XCTAssertEqual(distribution.rangeValues.last, 22)
        XCTAssertEqual(distribution.rangeWeights.count, 11)

        let peakIndex = expectedPeakIndex(rangeSize: distribution.rangeValues.count)
        assertPeakDominates(distribution.rangeWeights, peakIndex: peakIndex)
    }

    func testDistribution_NegativeMinimum_5Agility8Instinct() async {
        let strategy = ElfDodgeDistributionStrategy()
        let distribution = strategy.distribution(agility: 5, instinct: 8, attackerLevel: Self.testLevel)

        XCTAssertEqual(distribution.minimumChance, -3)
        XCTAssertEqual(distribution.maximumChance, 5)
        XCTAssertEqual(distribution.rangeValues.count, 9)
        XCTAssertEqual(distribution.rangeValues.first, -3)
        XCTAssertEqual(distribution.rangeValues.last, 5)

        let peakIndex = expectedPeakIndex(rangeSize: distribution.rangeValues.count)
        assertPeakDominates(distribution.rangeWeights, peakIndex: peakIndex)
    }

    func testDistribution_HighAgility_110Agility10Instinct() async {
        let strategy = ElfDodgeDistributionStrategy()
        let distribution = strategy.distribution(agility: 110, instinct: 10, attackerLevel: Self.testLevel)

        XCTAssertEqual(distribution.minimumChance, 100)
        XCTAssertEqual(distribution.maximumChance, 100)
        XCTAssertEqual(distribution.rangeValues.count, 1)
        XCTAssertEqual(distribution.rangeValues.first, 100)
        XCTAssertEqual(distribution.rangeWeights.first, 1)
        XCTAssertTrue(distribution.hasRange)
    }

    func testDistribution_MinEqualsMax_100Agility0Instinct() async {
        let strategy = ElfDodgeDistributionStrategy()
        let distribution = strategy.distribution(agility: 100, instinct: 0, attackerLevel: Self.testLevel)

        XCTAssertEqual(distribution.minimumChance, 100)
        XCTAssertEqual(distribution.maximumChance, 100)
        XCTAssertEqual(distribution.rangeValues.count, 1)
        XCTAssertEqual(distribution.rangeValues.first, 100)
        XCTAssertTrue(distribution.hasRange)
    }

    func testDistribution_ZeroDifference_10Agility10Instinct() async {
        let strategy = ElfDodgeDistributionStrategy()
        let distribution = strategy.distribution(agility: 10, instinct: 10, attackerLevel: Self.testLevel)

        XCTAssertEqual(distribution.minimumChance, 0)
        XCTAssertEqual(distribution.maximumChance, 10)
        XCTAssertEqual(distribution.rangeValues.count, 11)
        XCTAssertEqual(distribution.rangeValues, Array(0...10).map { Int16($0) })
        XCTAssertTrue(distribution.hasRange)
    }

    func testDistribution_SmallDifference_15Agility12Instinct() async {
        let strategy = ElfDodgeDistributionStrategy()
        let distribution = strategy.distribution(agility: 15, instinct: 12, attackerLevel: Self.testLevel)

        XCTAssertEqual(distribution.minimumChance, 3)
        XCTAssertEqual(distribution.maximumChance, 15)
        XCTAssertEqual(distribution.rangeValues.count, 13)
        XCTAssertEqual(distribution.rangeValues.first, 3)
        XCTAssertEqual(distribution.rangeValues.last, 15)

        let peakIndex = expectedPeakIndex(rangeSize: distribution.rangeValues.count)
        assertPeakDominates(distribution.rangeWeights, peakIndex: peakIndex)
    }

    func testDistribution_EdgeCase_LargeNegative_1Agility100Instinct() async {
        let strategy = ElfDodgeDistributionStrategy()
        let distribution = strategy.distribution(agility: 1, instinct: 100, attackerLevel: Self.testLevel)

        XCTAssertEqual(distribution.minimumChance, -99)
        XCTAssertEqual(distribution.maximumChance, 1)
        XCTAssertEqual(distribution.rangeValues.count, 101)
        XCTAssertEqual(distribution.rangeValues.first, -99)
        XCTAssertEqual(distribution.rangeValues.last, 1)
    }

    // MARK: - Level scaling

    /// Higher attacker level → multiplier grows → bigger suppression → lower minimum.
    func testDistribution_LevelScalesSuppression() async {
        let strategy = ElfDodgeDistributionStrategy()
        let low = strategy.distribution(agility: 40, instinct: 20, attackerLevel: 1)
        let high = strategy.distribution(agility: 40, instinct: 20, attackerLevel: 12)
        XCTAssertGreaterThan(low.minimumChance, high.minimumChance,
                             "Higher-level intuition must suppress agility harder (lower minimum)")
    }

    // MARK: - Stage 2 Tests (Dodge Success Check)

    func testStage2_NegativeChance_AlwaysFails() async {
        let service = ElfDodgeService()
        var failures = 0
        for _ in 0..<200 {
            let result = service.calculateDodge(agility: 5, instinct: 10, attackerLevel: Self.testLevel)
            if result.selectedChance < 0 {
                failures += result.success ? 0 : 1
            }
        }
        XCTAssertGreaterThan(failures, 0, "Should have some negative chance selections")
    }

    func testStage2_100PlusChance_AlwaysSucceeds() async {
        let service = ElfDodgeService()
        let result = service.calculateDodge(agility: 110, instinct: 5, attackerLevel: Self.testLevel)
        XCTAssertTrue(result.success, "100+ chance should always succeed")
        XCTAssertNil(result.stage2Roll)
        XCTAssertEqual(result.selectedChance, 105)
    }

    func testStage2_100Chance_AlwaysSucceeds() async {
        let service = ElfDodgeService()
        let result = service.calculateDodge(agility: 100, instinct: 0, attackerLevel: Self.testLevel)
        XCTAssertTrue(result.success)
        XCTAssertNil(result.stage2Roll)
    }

    // MARK: - Integration Tests

    func testFullCalculation_VerifyResultStructure() async {
        let service = ElfDodgeService()
        let result = service.calculateDodge(agility: 22, instinct: 10, attackerLevel: Self.testLevel)

        XCTAssertNotNil(result.distribution)
        XCTAssertGreaterThanOrEqual(result.selectedChance, 12)
        XCTAssertLessThanOrEqual(result.selectedChance, 22)

        if result.selectedChance > 0 && result.selectedChance < 100 {
            XCTAssertNotNil(result.stage2Roll)
            XCTAssertGreaterThanOrEqual(result.stage2Roll ?? 0, 1)
            XCTAssertLessThanOrEqual(result.stage2Roll ?? 0, 100)
        }
    }

    func testDeterministicBehavior_SameInputDifferentOutputs() async {
        let service = ElfDodgeService()
        var results: [DodgeCalculationResult] = []
        for _ in 0..<100 {
            results.append(service.calculateDodge(agility: 20, instinct: 10, attackerLevel: Self.testLevel))
        }

        let uniqueChances = Set(results.map { $0.selectedChance })
        XCTAssertGreaterThan(uniqueChances.count, 1)

        let successes = results.filter { $0.success }.count
        XCTAssertGreaterThan(successes, 0)
        XCTAssertLessThan(successes, 100)
    }

    // MARK: - Statistical Tests

    func testStatistical_PeakAtMinimumIsMostFrequent() async {
        let service = ElfDodgeService()
        let iterations = 5000

        var selections: [Int16: Int] = [:]
        for _ in 0..<iterations {
            let result = service.calculateDodge(agility: 20, instinct: 10, attackerLevel: Self.testLevel)
            selections[result.selectedChance, default: 0] += 1
        }

        let minimumCount = selections[10] ?? 0
        let maximumCount = selections[20] ?? 0
        XCTAssertGreaterThan(minimumCount, maximumCount,
                             "Peak position 0.0 → minimum value should be selected more than maximum")
    }

    // MARK: - Edge Case Tests

    func testEdgeCase_AgilityEquals1_InstinctEquals100() async {
        let service = ElfDodgeService()
        let result = service.calculateDodge(agility: 1, instinct: 100, attackerLevel: Self.testLevel)

        XCTAssertEqual(result.distribution.minimumChance, -99)
        XCTAssertEqual(result.distribution.maximumChance, 1)
        XCTAssertFalse(result.success, "With such low agility, should almost always fail")
    }

    func testEdgeCase_BothEqual100() async {
        let service = ElfDodgeService()
        let result = service.calculateDodge(agility: 100, instinct: 100, attackerLevel: Self.testLevel)

        XCTAssertEqual(result.distribution.minimumChance, 0)
        XCTAssertEqual(result.distribution.maximumChance, 100)
    }
}

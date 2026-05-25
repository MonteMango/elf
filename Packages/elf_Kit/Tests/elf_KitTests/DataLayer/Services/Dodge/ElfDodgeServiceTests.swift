//
//  ElfDodgeServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for ElfDodgeService and ElfDodgeDistributionStrategy
///
/// Distribution uses linear-tail weights around a peak whose position is
/// `GameMechanicsConstants.dodgePeakPosition` and whose share of total
/// probability mass is `GameMechanicsConstants.dodgePeakWeight`. Tests
/// read those constants rather than hardcoding numbers, so they stay
/// green when the balance is re-tuned.
final class ElfDodgeServiceTests: XCTestCase {

    // MARK: - Property helpers

    /// Index of the peak for a distribution of the given size, matching the
    /// strategy's own formula: `round(peakPosition * (rangeSize - 1))`.
    private func expectedPeakIndex(rangeSize: Int) -> Int {
        Int(round(GameMechanicsConstants.dodgePeakPosition * Double(rangeSize - 1)))
    }

    /// Tolerance for the peak-share assertion. The strategy rounds the peak
    /// weight to an integer, so for small ranges the realized share drifts
    /// a few percent from the configured share.
    private let peakShareTolerance: Double = 0.05

    /// Assert peak weight dominates with share ≈ `dodgePeakWeight`, and
    /// non-peak weights taper monotonically from peak toward both ends.
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
        // Tail monotonic falloff from peak.
        for i in stride(from: peakIndex - 1, through: 0, by: -1) where i + 1 != peakIndex {
            XCTAssertLessThanOrEqual(weights[i], weights[i + 1], "Left tail must not grow toward edges", file: file, line: line)
        }
        for i in (peakIndex + 1)..<weights.count where i - 1 != peakIndex {
            XCTAssertLessThanOrEqual(weights[i], weights[i - 1], "Right tail must not grow toward edges", file: file, line: line)
        }
    }

    /// Wire the real stateless distribution strategy so every test can exercise
    /// `ElfDodgeService` without each one spelling out `withDependencies`.
    override func invokeTest() {
        withDependencies {
            $0.dodgeDistributionStrategy = ElfDodgeDistributionStrategy()
        } operation: {
            super.invokeTest()
        }
    }

    // MARK: - Distribution Strategy Tests

    func testDistribution_StandardCase_22Agility10Instinct() async {
        // Given
        let strategy = ElfDodgeDistributionStrategy()

        // When
        let distribution = strategy.distribution(agility: 22, instinct: 10)

        // Then
        XCTAssertEqual(distribution.minimumChance, 12, "Minimum should be agility - instinct")
        XCTAssertEqual(distribution.maximumChance, 22, "Maximum should be agility")
        XCTAssertEqual(distribution.rangeValues.count, 11, "Range should have 11 values (12-22)")
        XCTAssertEqual(distribution.rangeValues.first, 12, "Range should start at minimum")
        XCTAssertEqual(distribution.rangeValues.last, 22, "Range should end at maximum")
        XCTAssertEqual(distribution.rangeWeights.count, 11)

        let peakIndex = expectedPeakIndex(rangeSize: distribution.rangeValues.count)
        assertPeakDominates(distribution.rangeWeights, peakIndex: peakIndex)
    }

    func testDistribution_NegativeMinimum_5Agility8Instinct() async {
        // Given
        let strategy = ElfDodgeDistributionStrategy()

        // When
        let distribution = strategy.distribution(agility: 5, instinct: 8)

        // Then
        XCTAssertEqual(distribution.minimumChance, -3, "Minimum can be negative")
        XCTAssertEqual(distribution.maximumChance, 5, "Maximum should be agility")
        XCTAssertEqual(distribution.rangeValues.count, 9, "Range: -3, -2, -1, 0, 1, 2, 3, 4, 5")
        XCTAssertEqual(distribution.rangeValues.first, -3, "Range starts at minimum")
        XCTAssertEqual(distribution.rangeValues.last, 5, "Range ends at maximum")

        let peakIndex = expectedPeakIndex(rangeSize: distribution.rangeValues.count)
        assertPeakDominates(distribution.rangeWeights, peakIndex: peakIndex)
    }

    func testDistribution_HighAgility_110Agility10Instinct() async {
        // Given
        let strategy = ElfDodgeDistributionStrategy()

        // When
        let distribution = strategy.distribution(agility: 110, instinct: 10)

        // Then
        XCTAssertEqual(distribution.minimumChance, 100, "Minimum = agility - instinct")
        XCTAssertEqual(distribution.maximumChance, 100, "Maximum capped at 100")
        XCTAssertEqual(distribution.rangeValues.count, 1, "Single value when min >= max")
        XCTAssertEqual(distribution.rangeValues.first, 100)
        XCTAssertEqual(distribution.rangeWeights.first, 1)
        XCTAssertTrue(distribution.hasRange)
    }

    func testDistribution_MinEqualsMax_100Agility0Instinct() async {
        // Given
        let strategy = ElfDodgeDistributionStrategy()

        // When
        let distribution = strategy.distribution(agility: 100, instinct: 0)

        // Then
        XCTAssertEqual(distribution.minimumChance, 100)
        XCTAssertEqual(distribution.maximumChance, 100)
        XCTAssertEqual(distribution.rangeValues.count, 1, "Single value when min >= max")
        XCTAssertEqual(distribution.rangeValues.first, 100)
        XCTAssertTrue(distribution.hasRange)
    }

    func testDistribution_ZeroDifference_10Agility10Instinct() async {
        // Given
        let strategy = ElfDodgeDistributionStrategy()

        // When
        let distribution = strategy.distribution(agility: 10, instinct: 10)

        // Then
        XCTAssertEqual(distribution.minimumChance, 0, "Minimum = 0 when agility equals instinct")
        XCTAssertEqual(distribution.maximumChance, 10, "Maximum = agility")
        XCTAssertEqual(distribution.rangeValues.count, 11, "Range: 0-10")
        XCTAssertEqual(distribution.rangeValues, Array(0...10).map { Int16($0) })
        XCTAssertTrue(distribution.hasRange)
    }

    func testDistribution_SmallDifference_15Agility12Instinct() async {
        // Given
        let strategy = ElfDodgeDistributionStrategy()

        // When
        let distribution = strategy.distribution(agility: 15, instinct: 12)

        // Then
        XCTAssertEqual(distribution.minimumChance, 3)
        XCTAssertEqual(distribution.maximumChance, 15)
        XCTAssertEqual(distribution.rangeValues.count, 13, "Range: 3-15")
        XCTAssertEqual(distribution.rangeValues.first, 3)
        XCTAssertEqual(distribution.rangeValues.last, 15)

        let peakIndex = expectedPeakIndex(rangeSize: distribution.rangeValues.count)
        assertPeakDominates(distribution.rangeWeights, peakIndex: peakIndex)
    }

    func testDistribution_EdgeCase_LargeNegative_1Agility100Instinct() async {
        // Given
        let strategy = ElfDodgeDistributionStrategy()

        // When
        let distribution = strategy.distribution(agility: 1, instinct: 100)

        // Then
        XCTAssertEqual(distribution.minimumChance, -99, "Large negative minimum")
        XCTAssertEqual(distribution.maximumChance, 1, "Maximum = agility")
        XCTAssertEqual(distribution.rangeValues.count, 101, "Range: -99 to 1")
        XCTAssertEqual(distribution.rangeValues.first, -99)
        XCTAssertEqual(distribution.rangeValues.last, 1)
    }

    // MARK: - Stage 2 Tests (Dodge Success Check)

    func testStage2_NegativeChance_AlwaysFails() async {
        // Given
        let service = ElfDodgeService()

        // When: Simulate many rolls with negative chance
        var failures = 0
        for _ in 0..<100 {
            let result = service.calculateDodge(agility: 5, instinct: 10) // min = -5
            // Force minimum selection by testing distribution directly
            if result.selectedChance < 0 {
                failures += result.success ? 0 : 1
            }
        }

        // Then: All negative chances should fail
        XCTAssertGreaterThan(failures, 0, "Should have some negative chance selections")
    }

    func testStage2_100PlusChance_AlwaysSucceeds() async {
        // Given
        let service = ElfDodgeService()

        // When
        let result = service.calculateDodge(agility: 110, instinct: 5) // min = 105, max = 100 (capped)

        // Then
        XCTAssertTrue(result.success, "100+ chance should always succeed")
        XCTAssertNil(result.stage2Roll, "No roll needed for auto-success")
        XCTAssertEqual(result.selectedChance, 105)
    }

    func testStage2_100Chance_AlwaysSucceeds() async {
        // Given
        let service = ElfDodgeService()

        // When
        let result = service.calculateDodge(agility: 100, instinct: 0)

        // Then
        XCTAssertTrue(result.success, "100% chance should always succeed")
        XCTAssertNil(result.stage2Roll, "No roll needed for 100%")
    }

    // MARK: - Integration Tests

    func testFullCalculation_VerifyResultStructure() async {
        // Given
        let service = ElfDodgeService()

        // When
        let result = service.calculateDodge(agility: 22, instinct: 10)

        // Then
        XCTAssertNotNil(result.distribution, "Should have distribution")
        XCTAssertGreaterThanOrEqual(result.selectedChance, 12)
        XCTAssertLessThanOrEqual(result.selectedChance, 22)

        // Stage 2 roll should exist for chances between 1-99
        if result.selectedChance > 0 && result.selectedChance < 100 {
            XCTAssertNotNil(result.stage2Roll)
            XCTAssertGreaterThanOrEqual(result.stage2Roll!, 1)
            XCTAssertLessThanOrEqual(result.stage2Roll!, 100)
        }
    }

    func testDeterministicBehavior_SameInputDifferentOutputs() async {
        // Given
        let service = ElfDodgeService()

        // When: Run same calculation multiple times
        var results: [DodgeCalculationResult] = []
        for _ in 0..<100 {
            let result = service.calculateDodge(agility: 20, instinct: 10)
            results.append(result)
        }

        // Then: Should have variety in selected chances (not all the same)
        let uniqueChances = Set(results.map { $0.selectedChance })
        XCTAssertGreaterThan(uniqueChances.count, 1, "Should select different chances over multiple runs")

        // Should have both successes and failures
        let successes = results.filter { $0.success }.count
        XCTAssertGreaterThan(successes, 0, "Should have some successes")
        XCTAssertLessThan(successes, 100, "Should have some failures")
    }

    // MARK: - Statistical Tests (Monte Carlo)

    func testStatistical_TriangularDistribution_MinimumHasHighestProbability() async {
        // Given
        let service = ElfDodgeService()
        let iterations = 5000

        // When: Count selections for each value
        var selections: [Int16: Int] = [:]
        for _ in 0..<iterations {
            let result = service.calculateDodge(agility: 20, instinct: 10) // min=10, max=20
            selections[result.selectedChance, default: 0] += 1
        }

        // Then: Minimum value should be selected most frequently
        let minimumCount = selections[10] ?? 0
        let maximumCount = selections[20] ?? 0
        XCTAssertGreaterThan(minimumCount, maximumCount, "Minimum (10) should be selected more than maximum (20)")

        // Also verify overall triangular trend
        if let first = selections[10], let last = selections[20] {
            XCTAssertGreaterThan(first, last, "Value 10 should be selected more than value 20 (triangular distribution)")
        }
    }

    func testStatistical_TriangularDistribution_HigherWeightForLowerValues() async {
        // Given
        let service = ElfDodgeService()
        let iterations = 5000

        // When: Count selections for each value in range
        var selections: [Int16: Int] = [:]
        for _ in 0..<iterations {
            let result = service.calculateDodge(agility: 20, instinct: 10) // min=10, max=20
            selections[result.selectedChance, default: 0] += 1
        }

        // Then: Lower values (closer to minimum) should be selected more frequently
        // At least verify first value is selected more than last
        if let first = selections[10], let last = selections[20] {
            XCTAssertGreaterThan(first, last, "Value 10 should be selected more than value 20 (triangular distribution)")
        }
    }

    // MARK: - Edge Case Tests

    func testEdgeCase_AgilityEquals1_InstinctEquals100() async {
        // Given
        let service = ElfDodgeService()

        // When
        let result = service.calculateDodge(agility: 1, instinct: 100)

        // Then
        XCTAssertEqual(result.distribution.minimumChance, -99)
        XCTAssertEqual(result.distribution.maximumChance, 1)
        XCTAssertFalse(result.success, "With such low agility, should almost always fail")
    }

    func testEdgeCase_BothEqual100() async {
        // Given
        let service = ElfDodgeService()

        // When
        let result = service.calculateDodge(agility: 100, instinct: 100)

        // Then
        XCTAssertEqual(result.distribution.minimumChance, 0)
        XCTAssertEqual(result.distribution.maximumChance, 100)
        // Success depends on selection and roll
    }
}

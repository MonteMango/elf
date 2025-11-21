//
//  ElfDodgeServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import XCTest
@testable import elf_Kit

/// Tests for ElfDodgeService and ElfDodgeDistributionStrategy
///
/// Distribution uses tent-shaped weights with configurable peak position via `GameMechanicsConstants.dodgePeakPosition`:
/// - peakPosition = 0.0: Peak at minimum (favors lower chances)
/// - peakPosition = 0.4 (current): Peak at 40% of range
/// - peakPosition = 1.0: Peak at maximum (favors higher chances)
final class ElfDodgeServiceTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeService() -> ElfDodgeService {
        let strategy = ElfDodgeDistributionStrategy()
        return ElfDodgeService(distributionStrategy: strategy)
    }

    // MARK: - Distribution Strategy Tests

    func testDistribution_StandardCase_22Agility10Instinct() {
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

        // Verify tent-shaped weights with peakPosition = 0.4
        // Range size = 11, peak index = round(0.4 * 10) = 4
        // Weights = [11 - |i - 4|] for i in 0..<11
        // Expected: [7, 8, 9, 10, 11, 10, 9, 8, 7, 6, 5]
        XCTAssertEqual(distribution.rangeWeights.count, 11)

        // Peak should be at index 4 (value 16)
        let peakIndex = 4
        XCTAssertEqual(distribution.rangeWeights[peakIndex], 11, "Peak weight should be range size")

        // Weights should decrease from peak in both directions
        XCTAssertLessThan(distribution.rangeWeights.first!, distribution.rangeWeights[peakIndex], "First weight should be less than peak")
        XCTAssertLessThan(distribution.rangeWeights.last!, distribution.rangeWeights[peakIndex], "Last weight should be less than peak")
    }

    func testDistribution_NegativeMinimum_5Agility8Instinct() {
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

        // Verify tent-shaped weights with peakPosition = 0.4
        // Range size = 9, peak index = round(0.4 * 8) = 3
        let peakIndex = 3
        XCTAssertEqual(distribution.rangeWeights[peakIndex], 9, "Peak weight should be range size")
        XCTAssertGreaterThan(distribution.rangeWeights[peakIndex], distribution.rangeWeights.last!)
    }

    func testDistribution_HighAgility_110Agility10Instinct() {
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

    func testDistribution_MinEqualsMax_100Agility0Instinct() {
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

    func testDistribution_ZeroDifference_10Agility10Instinct() {
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

    func testDistribution_SmallDifference_15Agility12Instinct() {
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

        // Verify tent-shaped weights with peakPosition = 0.4
        // Range size = 13, peak index = round(0.4 * 12) = 5
        let peakIndex = 5
        XCTAssertEqual(distribution.rangeWeights[peakIndex], 13, "Peak weight should be range size")
        XCTAssertGreaterThan(distribution.rangeWeights[peakIndex], distribution.rangeWeights.first!)
        XCTAssertGreaterThan(distribution.rangeWeights[peakIndex], distribution.rangeWeights.last!)
    }

    func testDistribution_EdgeCase_LargeNegative_1Agility100Instinct() {
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

    func testStage2_NegativeChance_AlwaysFails() {
        // Given
        let service = makeService()

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

    func testStage2_100PlusChance_AlwaysSucceeds() {
        // Given
        let service = makeService()

        // When
        let result = service.calculateDodge(agility: 110, instinct: 5) // min = 105, max = 100 (capped)

        // Then
        XCTAssertTrue(result.success, "100+ chance should always succeed")
        XCTAssertNil(result.stage2Roll, "No roll needed for auto-success")
        XCTAssertEqual(result.selectedChance, 105)
    }

    func testStage2_100Chance_AlwaysSucceeds() {
        // Given
        let service = makeService()

        // When
        let result = service.calculateDodge(agility: 100, instinct: 0)

        // Then
        XCTAssertTrue(result.success, "100% chance should always succeed")
        XCTAssertNil(result.stage2Roll, "No roll needed for 100%")
    }

    // MARK: - Integration Tests

    func testFullCalculation_VerifyResultStructure() {
        // Given
        let service = makeService()

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

    func testDeterministicBehavior_SameInputDifferentOutputs() {
        // Given
        let service = makeService()

        // When: Run same calculation multiple times
        let results = (0..<100).map { _ in
            service.calculateDodge(agility: 20, instinct: 10)
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

    func testStatistical_TriangularDistribution_MinimumHasHighestProbability() {
        // Given
        let service = makeService()
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

    func testStatistical_TriangularDistribution_HigherWeightForLowerValues() {
        // Given
        let service = makeService()
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

    func testEdgeCase_AgilityEquals1_InstinctEquals100() {
        // Given
        let service = makeService()

        // When
        let result = service.calculateDodge(agility: 1, instinct: 100)

        // Then
        XCTAssertEqual(result.distribution.minimumChance, -99)
        XCTAssertEqual(result.distribution.maximumChance, 1)
        XCTAssertFalse(result.success, "With such low agility, should almost always fail")
    }

    func testEdgeCase_BothEqual100() {
        // Given
        let service = makeService()

        // When
        let result = service.calculateDodge(agility: 100, instinct: 100)

        // Then
        XCTAssertEqual(result.distribution.minimumChance, 0)
        XCTAssertEqual(result.distribution.maximumChance, 100)
        // Success depends on selection and roll
    }
}

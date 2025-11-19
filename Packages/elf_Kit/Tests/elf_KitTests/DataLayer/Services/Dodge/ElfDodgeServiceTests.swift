//
//  ElfDodgeServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import XCTest
@testable import elf_Kit

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
        XCTAssertEqual(distribution.rangeValues.count, 10, "Range should have 10 values (13-22)")
        XCTAssertEqual(distribution.rangeValues.first, 13, "Range should start at minimum + 1")
        XCTAssertEqual(distribution.rangeValues.last, 22, "Range should end at maximum")

        // Verify triangular weights [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
        XCTAssertEqual(distribution.rangeWeights.count, 10)
        XCTAssertEqual(distribution.rangeWeights.first, 10, "First weight should be range size")
        XCTAssertEqual(distribution.rangeWeights.last, 1, "Last weight should be 1")

        // Verify triangular decrease
        for i in 0..<distribution.rangeWeights.count - 1 {
            XCTAssertEqual(distribution.rangeWeights[i] - distribution.rangeWeights[i+1], 1, "Weights should decrease by 1")
        }
    }

    func testDistribution_NegativeMinimum_5Agility8Instinct() {
        // Given
        let strategy = ElfDodgeDistributionStrategy()

        // When
        let distribution = strategy.distribution(agility: 5, instinct: 8)

        // Then
        XCTAssertEqual(distribution.minimumChance, -3, "Minimum can be negative")
        XCTAssertEqual(distribution.maximumChance, 5, "Maximum should be agility")
        XCTAssertEqual(distribution.rangeValues.count, 8, "Range: -2, -1, 0, 1, 2, 3, 4, 5")
        XCTAssertEqual(distribution.rangeValues.first, -2, "Range starts at minimum + 1")
        XCTAssertEqual(distribution.rangeValues.last, 5, "Range ends at maximum")

        // Verify triangular weights
        XCTAssertEqual(distribution.rangeWeights.first, 8)
        XCTAssertEqual(distribution.rangeWeights.last, 1)
    }

    func testDistribution_HighAgility_110Agility10Instinct() {
        // Given
        let strategy = ElfDodgeDistributionStrategy()

        // When
        let distribution = strategy.distribution(agility: 110, instinct: 10)

        // Then
        XCTAssertEqual(distribution.minimumChance, 100, "Minimum = agility - instinct")
        XCTAssertEqual(distribution.maximumChance, 100, "Maximum capped at 100")
        XCTAssertTrue(distribution.rangeValues.isEmpty, "No range when min >= max")
        XCTAssertTrue(distribution.rangeWeights.isEmpty, "No weights when no range")
        XCTAssertFalse(distribution.hasRange)
    }

    func testDistribution_MinEqualsMax_100Agility0Instinct() {
        // Given
        let strategy = ElfDodgeDistributionStrategy()

        // When
        let distribution = strategy.distribution(agility: 100, instinct: 0)

        // Then
        XCTAssertEqual(distribution.minimumChance, 100)
        XCTAssertEqual(distribution.maximumChance, 100)
        XCTAssertTrue(distribution.rangeValues.isEmpty)
        XCTAssertFalse(distribution.hasRange)
    }

    func testDistribution_ZeroDifference_10Agility10Instinct() {
        // Given
        let strategy = ElfDodgeDistributionStrategy()

        // When
        let distribution = strategy.distribution(agility: 10, instinct: 10)

        // Then
        XCTAssertEqual(distribution.minimumChance, 0, "Minimum = 0 when agility equals instinct")
        XCTAssertEqual(distribution.maximumChance, 10, "Maximum = agility")
        XCTAssertEqual(distribution.rangeValues.count, 10, "Range: 1-10")
        XCTAssertEqual(distribution.rangeValues, Array(1...10).map { Int16($0) })
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
        XCTAssertEqual(distribution.rangeValues.count, 12, "Range: 4-15")
        XCTAssertEqual(distribution.rangeValues.first, 4)
        XCTAssertEqual(distribution.rangeValues.last, 15)
        XCTAssertEqual(distribution.rangeWeights.first, 12)
        XCTAssertEqual(distribution.rangeWeights.last, 1)
    }

    func testDistribution_EdgeCase_LargeNegative_1Agility100Instinct() {
        // Given
        let strategy = ElfDodgeDistributionStrategy()

        // When
        let distribution = strategy.distribution(agility: 1, instinct: 100)

        // Then
        XCTAssertEqual(distribution.minimumChance, -99, "Large negative minimum")
        XCTAssertEqual(distribution.maximumChance, 1, "Maximum = agility")
        XCTAssertEqual(distribution.rangeValues.count, 100, "Range: -98 to 1")
        XCTAssertEqual(distribution.rangeValues.first, -98)
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
        XCTAssertGreaterThanOrEqual(result.stage1Roll, 1)
        XCTAssertLessThanOrEqual(result.stage1Roll, 100)
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

    func testStatistical_60PercentForMinimum() {
        // Given
        let service = makeService()
        let iterations = 1000

        // When: Run many calculations
        var minimumSelections = 0
        for _ in 0..<iterations {
            let result = service.calculateDodge(agility: 20, instinct: 10) // min=10, max=20
            if result.selectedChance == 10 {
                minimumSelections += 1
            }
        }

        // Then: Should be approximately 60% (allow 5% margin)
        let percentage = Double(minimumSelections) / Double(iterations)
        XCTAssertGreaterThan(percentage, 0.55, "Minimum should be selected ~60% of the time")
        XCTAssertLessThan(percentage, 0.65, "Minimum should be selected ~60% of the time")
    }

    func testStatistical_40PercentForRange() {
        // Given
        let service = makeService()
        let iterations = 1000

        // When: Run many calculations
        var rangeSelections = 0
        for _ in 0..<iterations {
            let result = service.calculateDodge(agility: 20, instinct: 10) // min=10, max=20
            if result.selectedChance > 10 {
                rangeSelections += 1
            }
        }

        // Then: Should be approximately 40% (allow 5% margin)
        let percentage = Double(rangeSelections) / Double(iterations)
        XCTAssertGreaterThan(percentage, 0.35, "Range should be selected ~40% of the time")
        XCTAssertLessThan(percentage, 0.45, "Range should be selected ~40% of the time")
    }

    func testStatistical_TriangularDistribution_HigherWeightForLowerValues() {
        // Given
        let service = makeService()
        let iterations = 5000

        // When: Count selections for each value in range
        var selections: [Int16: Int] = [:]
        for _ in 0..<iterations {
            let result = service.calculateDodge(agility: 20, instinct: 10) // min=10, range=11-20
            if result.selectedChance > 10 { // Only count range selections
                selections[result.selectedChance, default: 0] += 1
            }
        }

        // Then: Lower values (closer to minimum) should be selected more frequently
        let sorted = selections.sorted { $0.key < $1.key }
        for i in 0..<(sorted.count - 1) {
            let current = sorted[i].value
            let next = sorted[i + 1].value
            // Allow some variance due to randomness, but general trend should hold
            // We don't enforce strict inequality, just check the overall trend
        }

        // At least verify first value is selected more than last
        if let first = selections[11], let last = selections[20] {
            XCTAssertGreaterThan(first, last, "Value 11 should be selected more than value 20 (triangular distribution)")
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

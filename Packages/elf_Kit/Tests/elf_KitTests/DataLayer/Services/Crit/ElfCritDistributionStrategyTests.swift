//
//  ElfCritDistributionStrategyTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import XCTest
@testable import elf_Kit

/// Tests for ElfCritDistributionStrategy
///
/// Distribution uses tent-shaped weights with configurable peak position via `GameMechanicsConstants.critPeakPosition`:
/// - Minimum = power - instinct (can be negative)
/// - Maximum = min(power, 100) (capped at 100)
final class ElfCritDistributionStrategyTests: XCTestCase {

    // MARK: - Standard Cases

    func testDistribution_StandardCase_30Power10Instinct() async {
        // Given
        let strategy = ElfCritDistributionStrategy()

        // When
        let distribution = await strategy.distribution(power: 30, instinct: 10)

        // Then
        XCTAssertEqual(distribution.minimumChance, 20, "Minimum should be power - instinct")
        XCTAssertEqual(distribution.maximumChance, 30, "Maximum should be power")
        XCTAssertEqual(distribution.rangeValues.count, 11, "Range should have 11 values (20-30)")
        XCTAssertEqual(distribution.rangeValues.first, 20, "Range should start at minimum")
        XCTAssertEqual(distribution.rangeValues.last, 30, "Range should end at maximum")
        XCTAssertTrue(distribution.hasRange)
    }

    func testDistribution_NegativeMinimum_10Power20Instinct() async {
        // Given
        let strategy = ElfCritDistributionStrategy()

        // When
        let distribution = await strategy.distribution(power: 10, instinct: 20)

        // Then
        XCTAssertEqual(distribution.minimumChance, -10, "Minimum can be negative")
        XCTAssertEqual(distribution.maximumChance, 10, "Maximum should be power")
        XCTAssertEqual(distribution.rangeValues.count, 21, "Range: -10 to 10")
        XCTAssertEqual(distribution.rangeValues.first, -10, "Range starts at minimum")
        XCTAssertEqual(distribution.rangeValues.last, 10, "Range ends at maximum")
    }

    func testDistribution_PowerCappedAt100_150Power10Instinct() async {
        // Given
        let strategy = ElfCritDistributionStrategy()

        // When
        let distribution = await strategy.distribution(power: 150, instinct: 10)

        // Then
        XCTAssertEqual(distribution.minimumChance, 140, "Minimum = power - instinct")
        XCTAssertEqual(distribution.maximumChance, 100, "Maximum capped at 100")
        // When minimum >= maximum, only one value (minimum) is returned
        XCTAssertEqual(distribution.rangeValues.count, 1)
        XCTAssertEqual(distribution.rangeValues.first, 140)
    }

    func testDistribution_ZeroDifference_20Power20Instinct() async {
        // Given
        let strategy = ElfCritDistributionStrategy()

        // When
        let distribution = await strategy.distribution(power: 20, instinct: 20)

        // Then
        XCTAssertEqual(distribution.minimumChance, 0, "Minimum = 0 when power equals instinct")
        XCTAssertEqual(distribution.maximumChance, 20, "Maximum = power")
        XCTAssertEqual(distribution.rangeValues.count, 21, "Range: 0-20")
        XCTAssertEqual(distribution.rangeValues, Array(0...20).map { Int16($0) })
    }

    func testDistribution_ZeroPower_0Power0Instinct() async {
        // Given
        let strategy = ElfCritDistributionStrategy()

        // When
        let distribution = await strategy.distribution(power: 0, instinct: 0)

        // Then
        XCTAssertEqual(distribution.minimumChance, 0)
        XCTAssertEqual(distribution.maximumChance, 0)
        XCTAssertEqual(distribution.rangeValues.count, 1, "Single value when min >= max")
        XCTAssertEqual(distribution.rangeValues.first, 0)
        XCTAssertEqual(distribution.rangeWeights.first, 1)
    }

    func testDistribution_ZeroPower_0Power10Instinct() async {
        // Given
        let strategy = ElfCritDistributionStrategy()

        // When
        let distribution = await strategy.distribution(power: 0, instinct: 10)

        // Then
        XCTAssertEqual(distribution.minimumChance, -10, "Negative minimum")
        XCTAssertEqual(distribution.maximumChance, 0, "Maximum = power = 0")
        XCTAssertEqual(distribution.rangeValues.count, 11, "Range: -10 to 0")
        XCTAssertEqual(distribution.rangeValues.first, -10)
        XCTAssertEqual(distribution.rangeValues.last, 0)
    }

    // MARK: - Edge Cases

    func testDistribution_MinEqualsMax_50Power0Instinct() async {
        // Given
        let strategy = ElfCritDistributionStrategy()

        // When
        let distribution = await strategy.distribution(power: 50, instinct: 0)

        // Then
        XCTAssertEqual(distribution.minimumChance, 50)
        XCTAssertEqual(distribution.maximumChance, 50)
        XCTAssertEqual(distribution.rangeValues.count, 1, "Single value when min == max")
        XCTAssertEqual(distribution.rangeValues.first, 50)
        XCTAssertTrue(distribution.hasRange)
    }

    func testDistribution_LargeNegativeMinimum_5Power100Instinct() async {
        // Given
        let strategy = ElfCritDistributionStrategy()

        // When
        let distribution = await strategy.distribution(power: 5, instinct: 100)

        // Then
        XCTAssertEqual(distribution.minimumChance, -95, "Large negative minimum")
        XCTAssertEqual(distribution.maximumChance, 5, "Maximum = power")
        XCTAssertEqual(distribution.rangeValues.count, 101, "Range: -95 to 5")
        XCTAssertEqual(distribution.rangeValues.first, -95)
        XCTAssertEqual(distribution.rangeValues.last, 5)
    }

    func testDistribution_100Power0Instinct() async {
        // Given
        let strategy = ElfCritDistributionStrategy()

        // When
        let distribution = await strategy.distribution(power: 100, instinct: 0)

        // Then
        XCTAssertEqual(distribution.minimumChance, 100)
        XCTAssertEqual(distribution.maximumChance, 100)
        XCTAssertEqual(distribution.rangeValues.count, 1)
        XCTAssertEqual(distribution.rangeValues.first, 100)
    }

    // MARK: - Tent Distribution Weight Tests

    func testDistribution_TentWeights_HasPeak() async {
        // Given
        let strategy = ElfCritDistributionStrategy()

        // When
        let distribution = await strategy.distribution(power: 30, instinct: 10) // Range: 20-30

        // Then: Weights should form a tent shape
        XCTAssertEqual(distribution.rangeWeights.count, 11)

        // Find the peak (maximum weight)
        let maxWeight = distribution.rangeWeights.max()!
        let peakIndex = distribution.rangeWeights.firstIndex(of: maxWeight)!

        // Peak should be the range size (tent peak = rangeSize)
        XCTAssertEqual(maxWeight, distribution.rangeValues.count)

        // Weights should decrease from peak in both directions (if not at edges)
        if peakIndex > 0 {
            XCTAssertLessThan(distribution.rangeWeights[peakIndex - 1], maxWeight)
        }
        if peakIndex < distribution.rangeWeights.count - 1 {
            XCTAssertLessThan(distribution.rangeWeights[peakIndex + 1], maxWeight)
        }
    }

    func testDistribution_AllWeightsPositive() async {
        // Given
        let strategy = ElfCritDistributionStrategy()

        // When
        let distribution = await strategy.distribution(power: 50, instinct: 20)

        // Then: All weights should be positive (at least 1)
        for weight in distribution.rangeWeights {
            XCTAssertGreaterThanOrEqual(weight, 1, "All weights should be at least 1")
        }
    }

    // MARK: - Computed Properties Tests

    func testDistribution_HasRange_ReturnsTrue() async {
        // Given
        let strategy = ElfCritDistributionStrategy()

        // When
        let distribution = await strategy.distribution(power: 20, instinct: 10)

        // Then
        XCTAssertTrue(distribution.hasRange)
        XCTAssertEqual(distribution.rangeValues.count, 11)
    }
}

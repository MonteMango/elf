//
//  ElfCritDistributionStrategyTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import XCTest
@testable import elf_Kit

/// Tests for `ElfCritDistributionStrategy`.
///
/// Crit suppression by defender's intuition is level-scaled:
/// `mult = critIntuitionSuppressionBaseMultiplier + critIntuitionSuppressionPerLevelDelta × attackerLevel`.
/// Tests use `attackerLevel: 0` so the multiplier collapses to the base
/// value (currently `0.8`); literal min assertions are computed via
/// `expectedSuppression(...)` instead of hard-coding `power − instinct`.
final class ElfCritDistributionStrategyTests: XCTestCase {

    private static let testLevel: Int = 0

    private static func expectedSuppression(instinct: Int16, level: Int = ElfCritDistributionStrategyTests.testLevel) -> Int16 {
        let mult = PeakLinearTailDistribution.multiplier(
            base: GameMechanicsConstants.critIntuitionSuppressionBaseMultiplier,
            perLevel: GameMechanicsConstants.critIntuitionSuppressionPerLevelDelta,
            attackerLevel: level
        )
        return Int16((Double(instinct) * mult).rounded())
    }

    // MARK: - Standard Cases

    func testDistribution_StandardCase_30Power10Instinct() async {
        let strategy = ElfCritDistributionStrategy()
        let distribution = strategy.distribution(power: 30, instinct: 10, attackerLevel: Self.testLevel)

        let expectedMin = Int16(30) - Self.expectedSuppression(instinct: 10)
        XCTAssertEqual(distribution.minimumChance, expectedMin)
        XCTAssertEqual(distribution.maximumChance, 30)
        XCTAssertEqual(distribution.rangeValues.count, Int(30 - expectedMin) + 1)
        XCTAssertEqual(distribution.rangeValues.first, expectedMin)
        XCTAssertEqual(distribution.rangeValues.last, 30)
        XCTAssertTrue(distribution.hasRange)
    }

    func testDistribution_NegativeMinimum_10Power20Instinct() async {
        let strategy = ElfCritDistributionStrategy()
        let distribution = strategy.distribution(power: 10, instinct: 20, attackerLevel: Self.testLevel)

        let expectedMin = Int16(10) - Self.expectedSuppression(instinct: 20)
        XCTAssertEqual(distribution.minimumChance, expectedMin)
        XCTAssertEqual(distribution.maximumChance, 10)
        XCTAssertEqual(distribution.rangeValues.count, Int(10 - expectedMin) + 1)
        XCTAssertEqual(distribution.rangeValues.first, expectedMin)
        XCTAssertEqual(distribution.rangeValues.last, 10)
    }

    func testDistribution_PowerCappedAt100_150Power10Instinct() async {
        let strategy = ElfCritDistributionStrategy()
        let distribution = strategy.distribution(power: 150, instinct: 10, attackerLevel: Self.testLevel)

        let expectedMin = Int16(150) - Self.expectedSuppression(instinct: 10)
        XCTAssertEqual(distribution.minimumChance, expectedMin)
        XCTAssertEqual(distribution.maximumChance, 100, "Maximum capped at 100")
        // When minimum >= maximum, only one value (minimum) is returned.
        XCTAssertEqual(distribution.rangeValues.count, 1)
        XCTAssertEqual(distribution.rangeValues.first, expectedMin)
    }

    func testDistribution_ZeroDifference_20Power20Instinct() async {
        let strategy = ElfCritDistributionStrategy()
        let distribution = strategy.distribution(power: 20, instinct: 20, attackerLevel: Self.testLevel)

        let expectedMin = Int16(20) - Self.expectedSuppression(instinct: 20)
        XCTAssertEqual(distribution.minimumChance, expectedMin)
        XCTAssertEqual(distribution.maximumChance, 20)
        XCTAssertEqual(distribution.rangeValues.first, expectedMin)
        XCTAssertEqual(distribution.rangeValues.last, 20)
    }

    func testDistribution_ZeroPower_0Power0Instinct() async {
        let strategy = ElfCritDistributionStrategy()
        let distribution = strategy.distribution(power: 0, instinct: 0, attackerLevel: Self.testLevel)

        XCTAssertEqual(distribution.minimumChance, 0)
        XCTAssertEqual(distribution.maximumChance, 0)
        XCTAssertEqual(distribution.rangeValues.count, 1)
        XCTAssertEqual(distribution.rangeValues.first, 0)
        XCTAssertEqual(distribution.rangeWeights.first, 1)
    }

    func testDistribution_ZeroPower_0Power10Instinct() async {
        let strategy = ElfCritDistributionStrategy()
        let distribution = strategy.distribution(power: 0, instinct: 10, attackerLevel: Self.testLevel)

        let expectedMin = Int16(0) - Self.expectedSuppression(instinct: 10)
        XCTAssertEqual(distribution.minimumChance, expectedMin)
        XCTAssertEqual(distribution.maximumChance, 0)
        XCTAssertEqual(distribution.rangeValues.first, expectedMin)
        XCTAssertEqual(distribution.rangeValues.last, 0)
    }

    // MARK: - Edge Cases

    func testDistribution_MinEqualsMax_50Power0Instinct() async {
        let strategy = ElfCritDistributionStrategy()
        let distribution = strategy.distribution(power: 50, instinct: 0, attackerLevel: Self.testLevel)

        XCTAssertEqual(distribution.minimumChance, 50)
        XCTAssertEqual(distribution.maximumChance, 50)
        XCTAssertEqual(distribution.rangeValues.count, 1)
        XCTAssertEqual(distribution.rangeValues.first, 50)
        XCTAssertTrue(distribution.hasRange)
    }

    func testDistribution_LargeNegativeMinimum_5Power100Instinct() async {
        let strategy = ElfCritDistributionStrategy()
        let distribution = strategy.distribution(power: 5, instinct: 100, attackerLevel: Self.testLevel)

        let expectedMin = Int16(5) - Self.expectedSuppression(instinct: 100)
        XCTAssertEqual(distribution.minimumChance, expectedMin)
        XCTAssertEqual(distribution.maximumChance, 5)
        XCTAssertEqual(distribution.rangeValues.first, expectedMin)
        XCTAssertEqual(distribution.rangeValues.last, 5)
    }

    func testDistribution_100Power0Instinct() async {
        let strategy = ElfCritDistributionStrategy()
        let distribution = strategy.distribution(power: 100, instinct: 0, attackerLevel: Self.testLevel)

        XCTAssertEqual(distribution.minimumChance, 100)
        XCTAssertEqual(distribution.maximumChance, 100)
        XCTAssertEqual(distribution.rangeValues.count, 1)
        XCTAssertEqual(distribution.rangeValues.first, 100)
    }

    // MARK: - Level scaling

    /// Higher attacker level → multiplier grows → defender's intuition suppresses
    /// crit harder → lower minimum.
    func testDistribution_LevelScalesSuppression() async {
        let strategy = ElfCritDistributionStrategy()
        let low = strategy.distribution(power: 40, instinct: 20, attackerLevel: 1)
        let high = strategy.distribution(power: 40, instinct: 20, attackerLevel: 12)
        XCTAssertGreaterThan(low.minimumChance, high.minimumChance,
                             "Higher-level intuition must suppress crit harder (lower minimum)")
    }

    // MARK: - Peak + linear-tail shape

    func testDistribution_PeakDominatesWithConfiguredShare() async {
        let strategy = ElfCritDistributionStrategy()
        let distribution = strategy.distribution(power: 30, instinct: 10, attackerLevel: Self.testLevel)

        XCTAssertGreaterThan(distribution.rangeWeights.count, 1)

        let expectedPeakIndex = Int(round(GameMechanicsConstants.critPeakPosition * Double(distribution.rangeValues.count - 1)))
        guard let maxWeight = distribution.rangeWeights.max() else {
            XCTFail("Weights array must not be empty")
            return
        }
        XCTAssertEqual(distribution.rangeWeights[expectedPeakIndex], maxWeight,
                       "Peak must land at index derived from critPeakPosition")

        let totalSum = distribution.rangeWeights.reduce(0, +)
        let actualShare = Double(maxWeight) / Double(totalSum)
        XCTAssertEqual(actualShare, GameMechanicsConstants.critPeakWeight, accuracy: 0.05)

        for i in stride(from: expectedPeakIndex - 1, through: 0, by: -1) where i + 1 != expectedPeakIndex {
            XCTAssertLessThanOrEqual(distribution.rangeWeights[i], distribution.rangeWeights[i + 1])
        }
        for i in (expectedPeakIndex + 1)..<distribution.rangeWeights.count where i - 1 != expectedPeakIndex {
            XCTAssertLessThanOrEqual(distribution.rangeWeights[i], distribution.rangeWeights[i - 1])
        }
    }

    func testDistribution_AllWeightsPositive() async {
        let strategy = ElfCritDistributionStrategy()
        let distribution = strategy.distribution(power: 50, instinct: 20, attackerLevel: Self.testLevel)
        for weight in distribution.rangeWeights {
            XCTAssertGreaterThanOrEqual(weight, 1, "All weights should be at least 1")
        }
    }

    // MARK: - Computed Properties

    func testDistribution_HasRange_ReturnsTrue() async {
        let strategy = ElfCritDistributionStrategy()
        let distribution = strategy.distribution(power: 20, instinct: 10, attackerLevel: Self.testLevel)
        XCTAssertTrue(distribution.hasRange)
        XCTAssertGreaterThan(distribution.rangeValues.count, 1)
    }
}

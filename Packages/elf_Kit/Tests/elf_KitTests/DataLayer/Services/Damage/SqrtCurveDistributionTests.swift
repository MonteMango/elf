//
//  SqrtCurveDistributionTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import XCTest
@testable import elf_Kit

/// Tests for the shared `SqrtCurveDistribution.distribution(stat:coefficient:)`
/// shaper used by both strength damage and damage reduction strategies.
///
/// `mean = sqrt(stat) × coefficient`. Distribution is always two adjacent
/// integers `[floor(mean), ceil(mean)]` (or one if the fraction is 0 or 1)
/// with weights summing to `weightTotal` (10).
final class SqrtCurveDistributionTests: XCTestCase {

    private func mean(of distribution: DamageDistribution) -> Double {
        let totalWeight = distribution.weights.reduce(0, +)
        guard totalWeight > 0 else { return 0 }
        let weightedSum = zip(distribution.values, distribution.weights)
            .reduce(0.0) { $0 + Double($1.0) * Double($1.1) }
        return weightedSum / Double(totalWeight)
    }

    // MARK: - Degenerate input

    func testZeroStat_ReturnsSingleZero() {
        let result = SqrtCurveDistribution.distribution(stat: 0, coefficient: 0.6)
        XCTAssertEqual(result.values, [0])
        XCTAssertEqual(result.weights, [1])
    }

    func testNegativeStat_ReturnsSingleZero() {
        let result = SqrtCurveDistribution.distribution(stat: -5, coefficient: 0.6)
        XCTAssertEqual(result.values, [0])
        XCTAssertEqual(result.weights, [1])
    }

    func testZeroCoefficient_ReturnsSingleZero() {
        let result = SqrtCurveDistribution.distribution(stat: 100, coefficient: 0)
        XCTAssertEqual(result.values, [0])
        XCTAssertEqual(result.weights, [1])
    }

    func testNegativeCoefficient_ReturnsSingleZero() {
        let result = SqrtCurveDistribution.distribution(stat: 100, coefficient: -0.5)
        XCTAssertEqual(result.values, [0])
        XCTAssertEqual(result.weights, [1])
    }

    // MARK: - Mean follows sqrt(stat) × coefficient

    func testMean_FollowsSqrtCurve_StrengthCoefficient() {
        let samples: [(stat: Int16, expectedMean: Double)] = [
            (1, 0.6), (4, 1.2), (9, 1.8), (16, 2.4), (25, 3.0),
            (36, 3.6), (49, 4.2), (64, 4.8), (81, 5.4), (100, 6.0)
        ]
        for (stat, expected) in samples {
            let dist = SqrtCurveDistribution.distribution(stat: stat, coefficient: 0.6)
            XCTAssertEqual(mean(of: dist), expected, accuracy: 0.1, "stat=\(stat)")
        }
    }

    func testMean_FollowsSqrtCurve_IntuitionReductionCoefficient() {
        // mean = sqrt(stat) × 0.12 — used by intuition reduction.
        let samples: [(stat: Int16, expectedMean: Double)] = [
            (25, 0.6), (100, 1.2), (400, 2.4)
        ]
        for (stat, expected) in samples {
            let dist = SqrtCurveDistribution.distribution(stat: stat, coefficient: 0.12)
            XCTAssertEqual(mean(of: dist), expected, accuracy: 0.1, "stat=\(stat)")
        }
    }

    func testMean_FollowsSqrtCurve_EnduranceReductionCoefficient() {
        // mean = sqrt(stat) × 0.18 — used by endurance reduction.
        let samples: [(stat: Int16, expectedMean: Double)] = [
            (25, 0.9), (100, 1.8), (400, 3.6)
        ]
        for (stat, expected) in samples {
            let dist = SqrtCurveDistribution.distribution(stat: stat, coefficient: 0.18)
            XCTAssertEqual(mean(of: dist), expected, accuracy: 0.1, "stat=\(stat)")
        }
    }

    // MARK: - Shape

    func testDistribution_AlwaysOneOrTwoValues() {
        for stat in stride(from: Int16(1), through: Int16(200), by: 7) {
            let dist = SqrtCurveDistribution.distribution(stat: stat, coefficient: 0.6)
            XCTAssertTrue(dist.values.count == 1 || dist.values.count == 2,
                          "stat=\(stat): expected 1 or 2 values, got \(dist.values.count)")
        }
    }

    func testTwoValueDistributions_AreAdjacent() {
        for stat in Int16(1)...Int16(200) {
            let dist = SqrtCurveDistribution.distribution(stat: stat, coefficient: 0.6)
            guard dist.values.count == 2 else { continue }
            XCTAssertEqual(dist.values[1], dist.values[0] + 1,
                           "stat=\(stat): two values must be adjacent integers")
        }
    }

    func testWeights_SumIsOneOrTen() {
        for stat: Int16 in [1, 5, 12, 36, 100, 200] {
            let dist = SqrtCurveDistribution.distribution(stat: stat, coefficient: 0.6)
            let sum = dist.weights.reduce(0, +)
            XCTAssertTrue(sum == 1 || sum == SqrtCurveDistribution.weightTotal,
                          "stat=\(stat): weight sum \(sum) — expected 1 (single value) or 10 (two values)")
            XCTAssertEqual(dist.values.count, dist.weights.count,
                           "stat=\(stat): values/weights length mismatch")
        }
    }

    // MARK: - Diminishing returns

    /// Doubling the stat grows the mean by ≈ √2 ≈ 1.41×, not 2×. This is the
    /// whole point of the sqrt curve.
    func testDoublingStatGivesSqrtTwoRatio() {
        let pairs: [(low: Int16, high: Int16)] = [
            (12, 24), (24, 48), (36, 72), (50, 100)
        ]
        for (low, high) in pairs {
            let lowMean = mean(of: SqrtCurveDistribution.distribution(stat: low, coefficient: 0.6))
            let highMean = mean(of: SqrtCurveDistribution.distribution(stat: high, coefficient: 0.6))
            XCTAssertEqual(highMean / lowMean, sqrt(2.0), accuracy: 0.1,
                           "stat \(low)→\(high): expected ~1.41× mean")
        }
    }

    /// Doubling the coefficient at a fixed stat must double the mean.
    func testDoublingCoefficient_DoublesMean() {
        for stat: Int16 in [16, 36, 64, 100] {
            let lowMean = mean(of: SqrtCurveDistribution.distribution(stat: stat, coefficient: 0.3))
            let highMean = mean(of: SqrtCurveDistribution.distribution(stat: stat, coefficient: 0.6))
            XCTAssertEqual(highMean / lowMean, 2.0, accuracy: 0.15,
                           "stat=\(stat): doubling coefficient must double the mean")
        }
    }
}

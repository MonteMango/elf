//
//  ElfStrengthDamageDistributionStrategyTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 11.07.25.
//

import XCTest
@testable import elf_Kit

/// Validates the `sqrt(strength) × 0.6` damage curve.
final class ElfStrengthDamageDistributionStrategyTests: XCTestCase {

    private let strategy = ElfStrengthDamageDistributionStrategy()

    // MARK: - Edge cases

    func testStrengthZero() {
        let result = strategy.distribution(for: 0)
        XCTAssertEqual(result.values, [0])
        XCTAssertEqual(result.weights, [1])
    }

    func testStrengthNegative() {
        let result = strategy.distribution(for: -5)
        XCTAssertEqual(result.values, [0])
        XCTAssertEqual(result.weights, [1])
    }

    // MARK: - Curve calibration

    /// Spot-check that the rolled mean matches `sqrt(strength) × 0.6` within
    /// the rounding tolerance imposed by integer weights ÷ 10.
    func testMeanFollowsSqrtCurve() {
        let samples: [(strength: Int16, expectedMean: Double)] = [
            (1, 0.6),
            (4, 1.2),
            (9, 1.8),
            (12, 2.08),
            (16, 2.4),
            (24, 2.94),
            (36, 3.6),
            (48, 4.16),
            (64, 4.8),
            (100, 6.0),
        ]
        for (strength, expectedMean) in samples {
            let dist = strategy.distribution(for: strength)
            let actualMean = computeMean(dist)
            XCTAssertEqual(actualMean, expectedMean, accuracy: 0.1,
                           "str=\(strength)")
        }
    }

    // MARK: - Distribution shape

    func testDistributionHasOneOrTwoValues() {
        for strength: Int16 in [1, 5, 12, 36, 100, 200] {
            let dist = strategy.distribution(for: strength)
            XCTAssertTrue(
                dist.values.count == 1 || dist.values.count == 2,
                "str=\(strength): expected 1 or 2 values, got \(dist.values.count)"
            )
        }
    }

    func testTwoValueDistributionsAreAdjacent() {
        for strength: Int16 in 1...200 {
            let dist = strategy.distribution(for: strength)
            guard dist.values.count == 2 else { continue }
            XCTAssertEqual(dist.values[1], dist.values[0] + 1,
                           "str=\(strength): values must be adjacent integers")
        }
    }

    func testWeightsAreValid() {
        for strength: Int16 in [1, 5, 12, 36, 100, 200] {
            let dist = strategy.distribution(for: strength)
            let sum = dist.weights.reduce(0, +)
            XCTAssertTrue(sum == 1 || sum == 10,
                          "str=\(strength): weight sum \(sum) — expected 1 (single value) or 10 (two values)")
            XCTAssertEqual(dist.values.count, dist.weights.count,
                           "str=\(strength): values/weights length mismatch")
        }
    }

    // MARK: - Diminishing returns

    /// Doubling Strength should grow the mean damage by ~`sqrt(2)` ≈ 1.41×,
    /// not 2×. This is the whole point of the sqrt curve.
    func testDoublingStrengthGivesSqrtTwoRatio() {
        let pairs: [(low: Int16, high: Int16)] = [
            (12, 24), (24, 48), (36, 72), (50, 100),
        ]
        for (low, high) in pairs {
            let lowMean = computeMean(strategy.distribution(for: low))
            let highMean = computeMean(strategy.distribution(for: high))
            let ratio = highMean / lowMean
            XCTAssertEqual(ratio, sqrt(2.0), accuracy: 0.1,
                           "str \(low)→\(high): expected ~1.41× mean, got \(ratio)")
        }
    }

    // MARK: - Helpers

    private func computeMean(_ distribution: DamageDistribution) -> Double {
        let weightSum = distribution.weights.reduce(0, +)
        guard weightSum > 0 else { return 0 }
        let weightedSum = zip(distribution.values, distribution.weights)
            .reduce(0.0) { $0 + Double($1.0) * Double($1.1) }
        return weightedSum / Double(weightSum)
    }
}

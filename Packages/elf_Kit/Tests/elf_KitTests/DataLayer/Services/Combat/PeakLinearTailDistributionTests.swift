//
//  PeakLinearTailDistributionTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import XCTest
@testable import elf_Kit

/// Tests for the shared `PeakLinearTailDistribution` shaper used by both
/// the dodge and crit chance strategies. Pins the geometry (peak position,
/// share, linear-falloff tails) and the level-scaling multiplier formula
/// in isolation, so dodge/crit strategy tests can rely on this as a
/// black box.
final class PeakLinearTailDistributionTests: XCTestCase {

    // MARK: - multiplier(base:perLevel:attackerLevel:)

    func testMultiplier_AtLevelZero_EqualsBase() {
        let result = PeakLinearTailDistribution.multiplier(base: 0.8, perLevel: 0.04, attackerLevel: 0)
        XCTAssertEqual(result, 0.8, accuracy: 1e-9)
    }

    func testMultiplier_ScalesLinearlyWithLevel() {
        let base = 0.8
        let perLevel = 0.04
        for level in 0...12 {
            let result = PeakLinearTailDistribution.multiplier(
                base: base, perLevel: perLevel, attackerLevel: level
            )
            XCTAssertEqual(result, base + perLevel * Double(level), accuracy: 1e-9, "level=\(level)")
        }
    }

    func testMultiplier_PerLevelZero_Constant() {
        for level in 0...20 {
            let result = PeakLinearTailDistribution.multiplier(
                base: 1.0, perLevel: 0.0, attackerLevel: level
            )
            XCTAssertEqual(result, 1.0, accuracy: 1e-9)
        }
    }

    // MARK: - range(...)

    func testRange_PrimaryAboveOpposing_StandardCase() {
        let result = PeakLinearTailDistribution.range(
            primaryStat: 30,
            opposingStat: 10,
            multiplier: 1.0,
            peakPosition: 0.0,
            peakWeightShare: 0.6
        )
        XCTAssertEqual(result.minimum, 20, "30 − round(10 × 1.0) = 20")
        XCTAssertEqual(result.maximum, 30)
        XCTAssertEqual(result.values.count, 11)
        XCTAssertEqual(result.values.first, 20)
        XCTAssertEqual(result.values.last, 30)
        XCTAssertEqual(result.weights.count, 11)
    }

    func testRange_NegativeMinimum_AllowedAndPropagated() {
        let result = PeakLinearTailDistribution.range(
            primaryStat: 5,
            opposingStat: 10,
            multiplier: 1.0,
            peakPosition: 0.0,
            peakWeightShare: 0.6
        )
        XCTAssertEqual(result.minimum, -5)
        XCTAssertEqual(result.maximum, 5)
        XCTAssertEqual(result.values.first, -5)
        XCTAssertEqual(result.values.last, 5)
    }

    func testRange_MaximumCappedAt100() {
        let result = PeakLinearTailDistribution.range(
            primaryStat: 150,
            opposingStat: 10,
            multiplier: 1.0,
            peakPosition: 0.0,
            peakWeightShare: 0.6
        )
        XCTAssertEqual(result.maximum, 100, "max must cap at 100")
        XCTAssertEqual(result.minimum, 140, "min ignores cap")
        // min >= max → degenerate single-bucket result.
        XCTAssertEqual(result.values, [140])
        XCTAssertEqual(result.weights, [1])
    }

    func testRange_HigherMultiplier_LowersMinimum() {
        let low = PeakLinearTailDistribution.range(
            primaryStat: 40, opposingStat: 20, multiplier: 0.8,
            peakPosition: 0.0, peakWeightShare: 0.6
        )
        let high = PeakLinearTailDistribution.range(
            primaryStat: 40, opposingStat: 20, multiplier: 1.2,
            peakPosition: 0.0, peakWeightShare: 0.6
        )
        XCTAssertGreaterThan(low.minimum, high.minimum,
                             "Higher multiplier should suppress harder (lower minimum)")
    }

    // MARK: - Peak geometry

    func testRange_PeakAtMinimumWhenPositionIsZero() {
        let result = PeakLinearTailDistribution.range(
            primaryStat: 30, opposingStat: 10, multiplier: 1.0,
            peakPosition: 0.0, peakWeightShare: 0.6
        )
        guard let maxWeight = result.weights.max() else {
            XCTFail("Weights must not be empty")
            return
        }
        XCTAssertEqual(result.weights.firstIndex(of: maxWeight), 0,
                       "peakPosition=0.0 should put the peak at the minimum (index 0)")
    }

    func testRange_PeakAtMaximumWhenPositionIsOne() {
        let result = PeakLinearTailDistribution.range(
            primaryStat: 30, opposingStat: 10, multiplier: 1.0,
            peakPosition: 1.0, peakWeightShare: 0.6
        )
        guard let maxWeight = result.weights.max() else {
            XCTFail("Weights must not be empty")
            return
        }
        XCTAssertEqual(result.weights.lastIndex(of: maxWeight), result.weights.count - 1,
                       "peakPosition=1.0 should put the peak at the maximum (last index)")
    }

    func testRange_PeakAtMiddleWhenPositionIsHalf() {
        let result = PeakLinearTailDistribution.range(
            primaryStat: 40, opposingStat: 10, multiplier: 1.0,
            peakPosition: 0.5, peakWeightShare: 0.6
        )
        let expectedPeakIndex = Int(round(0.5 * Double(result.values.count - 1)))
        guard let maxWeight = result.weights.max() else {
            XCTFail("Weights must not be empty")
            return
        }
        XCTAssertEqual(result.weights[expectedPeakIndex], maxWeight)
    }

    func testRange_PeakShareApproximatelyMatches() {
        let result = PeakLinearTailDistribution.range(
            primaryStat: 50, opposingStat: 10, multiplier: 1.0,
            peakPosition: 0.0, peakWeightShare: 0.6
        )
        guard let maxWeight = result.weights.max() else {
            XCTFail("Weights must not be empty")
            return
        }
        let total = result.weights.reduce(0, +)
        let share = Double(maxWeight) / Double(total)
        XCTAssertEqual(share, 0.6, accuracy: 0.05,
                       "Peak weight should claim ≈ 0.6 of total mass")
    }

    func testRange_TailsAreNonIncreasingFromPeak() {
        let result = PeakLinearTailDistribution.range(
            primaryStat: 40, opposingStat: 10, multiplier: 1.0,
            peakPosition: 0.5, peakWeightShare: 0.6
        )
        let peakIndex = Int(round(0.5 * Double(result.values.count - 1)))
        // Left of peak: weights should not increase moving away from peak.
        for i in stride(from: peakIndex - 1, through: 1, by: -1) {
            XCTAssertLessThanOrEqual(result.weights[i - 1], result.weights[i],
                                     "Left tail must taper from peak")
        }
        // Right of peak: same.
        for i in (peakIndex + 1)..<(result.weights.count - 1) {
            XCTAssertLessThanOrEqual(result.weights[i + 1], result.weights[i],
                                     "Right tail must taper from peak")
        }
    }

    func testRange_AllWeightsAreNonNegative() {
        let result = PeakLinearTailDistribution.range(
            primaryStat: 50, opposingStat: 20, multiplier: 1.0,
            peakPosition: 0.0, peakWeightShare: 0.6
        )
        for weight in result.weights {
            XCTAssertGreaterThanOrEqual(weight, 0)
        }
    }

    // MARK: - Degenerate input

    /// When `min == max` the result must collapse to a single value with
    /// weight 1 — no range to spread weights over.
    func testRange_MinEqualsMax_DegeneratesToSingleBucket() {
        let result = PeakLinearTailDistribution.range(
            primaryStat: 100, opposingStat: 0, multiplier: 1.0,
            peakPosition: 0.0, peakWeightShare: 0.6
        )
        XCTAssertEqual(result.minimum, 100)
        XCTAssertEqual(result.maximum, 100)
        XCTAssertEqual(result.values, [100])
        XCTAssertEqual(result.weights, [1])
    }

    /// `min > max` (extreme suppression past the cap) also collapses
    /// safely — returns minimum value with weight 1.
    func testRange_MinGreaterThanMax_StillCollapsesToSingleBucket() {
        let result = PeakLinearTailDistribution.range(
            primaryStat: 120, opposingStat: 5, multiplier: 1.0,
            peakPosition: 0.0, peakWeightShare: 0.6
        )
        XCTAssertEqual(result.minimum, 115)
        XCTAssertEqual(result.maximum, 100)
        XCTAssertEqual(result.values, [115])
        XCTAssertEqual(result.weights, [1])
    }
}

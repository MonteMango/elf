//
//  LevelCurveTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Testing
@testable import elf_Kit

/// Unit tests for the `LevelCurve` value type using a small, hand-verifiable curve.
///
/// Curve: `thresholds = [0, 10, 30, 60]` → 4 levels, per-level costs 10 / 20 / 30.
/// Expected values are concrete literals (never derived from the same table) so a
/// table/indexing bug cannot pass silently.
@Suite("LevelCurve", .tags(.progression))
struct LevelCurveTests {

    private let curve = LevelCurve(thresholds: [0, 10, 30, 60])

    @Test("maxLevel equals threshold count")
    func maxLevel() {
        #expect(curve.maxLevel == 4)
    }

    @Test("level(for:) maps XP to the enclosing level", arguments: [
        (-5, 1), (0, 1), (9, 1),
        (10, 2), (29, 2),
        (30, 3), (59, 3),
        (60, 4), (999, 4)
    ])
    func level(exp: Int, expected: Int) {
        #expect(curve.level(for: exp) == expected)
    }

    @Test("totalExpToReach(_:) returns the entry threshold, clamped", arguments: [
        (0, 0), (1, 0), (2, 10), (3, 30), (4, 60), (5, 60), (99, 60)
    ])
    func totalExpToReach(level: Int, expected: Int) {
        #expect(curve.totalExpToReach(level) == expected)
    }

    @Test("expToNextLevel(for:) returns the next entry threshold, 0 at cap", arguments: [
        (0, 10), (9, 10), (10, 30), (30, 60), (59, 60), (60, 0), (999, 0)
    ])
    func expToNextLevel(exp: Int, expected: Int) {
        #expect(curve.expToNextLevel(for: exp) == expected)
    }

    @Test("progress(for:) is the fraction within the current level, 1.0 at cap", arguments: [
        (0, 0.0), (5, 0.5), (10, 0.0), (20, 0.5), (60, 1.0), (999, 1.0)
    ])
    func progress(exp: Int, expected: Double) {
        #expect(abs(curve.progress(for: exp) - expected) < 0.0001)
    }

    @Test("level/totalExpToReach round-trip for every level")
    func roundTrip() {
        for level in 1...curve.maxLevel {
            #expect(curve.level(for: curve.totalExpToReach(level)) == level)
        }
    }
}

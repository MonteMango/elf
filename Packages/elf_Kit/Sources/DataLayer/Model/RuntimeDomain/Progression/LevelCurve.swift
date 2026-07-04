//
//  LevelCurve.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// A progression curve defined by an explicit table of cumulative XP thresholds.
///
/// `thresholds[i]` is the total accumulated XP required to *enter* level `i + 1`,
/// so `thresholds[0]` is always `0` (level 1 starts at zero XP) and the array length
/// equals `maxLevel`. Modelling the curve as a table (rather than a single
/// "XP per level" constant) lets each level cost a different amount — e.g. the
/// character curve where each level costs 25 XP more than the previous one.
///
/// The type is a pure value: `Sendable` + immutable, so it is safe to query from
/// any executor (main actor for UI, or the cooperative pool when e.g. simulating
/// many bots in parallel) without synchronisation.
struct LevelCurve: Sendable, Equatable {

    /// Cumulative total XP required to enter each level. `thresholds[0] == 0`.
    /// Must be non-empty and non-decreasing.
    let thresholds: [Int]

    /// Highest reachable level (equal to the number of thresholds).
    var maxLevel: Int { thresholds.count }

    /// The level for a given total XP: the highest level whose entry threshold is
    /// `<= exp`, clamped to `1...maxLevel`. Negative XP yields level 1.
    func level(for exp: Int) -> Int {
        var level = 1
        for index in thresholds.indices where exp >= thresholds[index] {
            level = index + 1
        }
        return level
    }

    /// Minimum total XP required to be the given level (inverse of `level(for:)`).
    /// `level` is clamped to `1...maxLevel`.
    func totalExpToReach(_ level: Int) -> Int {
        let clamped = min(max(level, 1), maxLevel)
        return thresholds[clamped - 1]
    }

    /// Total XP threshold needed to reach the *next* level, or `0` at max level.
    /// Returns the cumulative threshold (not the remaining delta) so it matches the
    /// value the result-overlay XP bar expects.
    func expToNextLevel(for exp: Int) -> Int {
        let level = level(for: exp)
        guard level < maxLevel else { return 0 }
        return thresholds[level]
    }

    /// Progress within the current level as a fraction `0.0...1.0`; returns `1.0`
    /// at max level.
    func progress(for exp: Int) -> Double {
        let level = level(for: exp)
        guard level < maxLevel else { return 1.0 }

        let levelStart = thresholds[level - 1]
        let levelEnd = thresholds[level]
        return Double(exp - levelStart) / Double(levelEnd - levelStart)
    }
}

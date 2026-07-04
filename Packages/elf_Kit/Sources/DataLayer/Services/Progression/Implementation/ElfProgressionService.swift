//
//  ElfProgressionService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Default implementation of progression calculation service.
///
/// Backed by two explicit XP-threshold tables (`LevelCurve`):
///
/// **Character** (levels 1–12): each level costs 25 XP more than the previous one.
/// Per-level cost: 100, 125, 150, … , 350. Cumulative entry thresholds:
/// `[0, 100, 225, 375, 550, 750, 975, 1225, 1500, 1800, 2125, 2475]`.
///
/// **Farming skills** (Foraging, Fishing, Mining), levels 1–12: preserves the legacy
/// `max(1, exp / 50)` mapping bit-for-bit (level 1 spans 0–99, every later level spans
/// 50 XP), so existing skill progression does not shift.
///
/// All work is pure synchronous value math with no stored mutable state, so calls run
/// on the caller's executor (main actor for UI, cooperative pool for off-main callers)
/// with no hop and no data races — deliberately *not* `@concurrent`.
public final class ElfProgressionService: ProgressionService {

    // MARK: - Curves

    private let character = LevelCurve(
        thresholds: [0, 100, 225, 375, 550, 750, 975, 1225, 1500, 1800, 2125, 2475]
    )

    /// Legacy `max(1, exp / 50)` mapping expressed as a threshold table:
    /// level 1 = 0, level k = k * 50 for k >= 2  ->  [0, 100, 150, … , 600].
    private let farming = LevelCurve(
        thresholds: [0, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600]
    )

    // MARK: - Initialization

    public init() {}

    // MARK: - ProgressionService

    public func calculateLevel(currentExp: Int) -> Int {
        character.level(for: currentExp)
    }

    public func totalExp(forLevel level: Int) -> Int {
        character.totalExpToReach(level)
    }

    public func expToNextLevel(currentExp: Int) -> Int {
        character.expToNextLevel(for: currentExp)
    }

    public func experienceTransition(previousExp: Int, gained: Int) -> ExperienceTransition {
        let newExp = previousExp + gained
        return ExperienceTransition(
            previousLevel: calculateLevel(currentExp: previousExp),
            previousExp: previousExp,
            previousExpToNext: expToNextLevel(currentExp: previousExp),
            newLevel: calculateLevel(currentExp: newExp),
            newExp: newExp,
            newExpToNext: expToNextLevel(currentExp: newExp)
        )
    }

    public func expProgress(currentExp: Int) -> Double {
        character.progress(for: currentExp)
    }

    public func farmingLevel(exp: Int) -> Int {
        farming.level(for: exp)
    }

    public func farmingProgress(exp: Int) -> Double {
        farming.progress(for: exp)
    }
}

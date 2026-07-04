//
//  ProgressionService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Service for calculating character progression (levels and experience)
///
/// Extracted from ElfInfo computed properties to separate business logic from data models.
/// Backed by explicit XP-threshold tables (`LevelCurve`), one per progression track.
///
/// **Character curve** (levels 1–12): each level costs 25 XP more than the previous
/// one — L1→2 = 100, L2→3 = 125, … , L11→12 = 350 (cumulative total to L12 = 2475).
///
/// **Farming skills** (Foraging, Fishing, Mining), levels 1–12: preserved legacy
/// `max(1, exp / 50)` mapping (level 1 spans 0–99, every later level spans 50 XP).
public protocol ProgressionService: Sendable {

    /// Calculates character level from total experience.
    ///
    /// - Parameter currentExp: Total accumulated experience
    /// - Returns: Level from 1 to 12
    func calculateLevel(currentExp: Int) -> Int

    /// Minimum total XP required for a character to be the given level.
    ///
    /// Inverse of `calculateLevel(currentExp:)` — used to seed AI elves at a desired
    /// level. `level` is clamped to the valid 1–12 range.
    ///
    /// - Parameter level: Desired character level
    /// - Returns: Total XP that places the character at exactly that level
    func totalExp(forLevel level: Int) -> Int

    /// Calculates XP threshold required to reach the next level
    ///
    /// - Parameter currentExp: Total accumulated experience
    /// - Returns: Total XP needed for next level, or 0 if at max level (12)
    func expToNextLevel(currentExp: Int) -> Int

    /// Builds the before→after level/exp bracket for gaining `gained` XP on top of
    /// `previousExp`. Single source of truth for the result-overlay XP bar, shared
    /// by every flow (hunt, dungeon) so the bracket math never drifts between them.
    ///
    /// - Parameters:
    ///   - previousExp: Total experience before the gain.
    ///   - gained: Experience gained (0 is valid — produces a no-op transition).
    /// - Returns: Paired previous/new level, exp, and exp-to-next values.
    func experienceTransition(previousExp: Int, gained: Int) -> ExperienceTransition

    /// Calculates progress within current level as a percentage
    ///
    /// - Parameter currentExp: Total accumulated experience
    /// - Returns: Progress from 0.0 to 1.0, returns 1.0 at max level
    func expProgress(currentExp: Int) -> Double

    /// Calculates farming skill level from total skill experience.
    ///
    /// Applicable to: Foraging, Fishing, Mining
    ///
    /// - Parameter exp: Total accumulated skill experience
    /// - Returns: Skill level from 1 to 12
    func farmingLevel(exp: Int) -> Int

    /// Calculates progress within current farming skill level as a percentage
    ///
    /// - Parameter exp: Total accumulated skill experience
    /// - Returns: Progress from 0.0 to 1.0, returns 1.0 at max level
    func farmingProgress(exp: Int) -> Double
}

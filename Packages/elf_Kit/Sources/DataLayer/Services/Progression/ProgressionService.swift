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
///
/// **Level Formulas**:
/// - Character level: `max(1, min(12, currentExp / 100))`
/// - Farming skill level: `max(1, min(12, exp / 50))`
///
/// **Experience Thresholds**:
/// - Character: 100 XP per level
/// - Farming skills: 50 XP per level
public protocol ProgressionService: Sendable {

    /// Calculates character level from total experience
    ///
    /// Formula: `max(1, min(12, currentExp / 100))`
    ///
    /// - Parameter currentExp: Total accumulated experience
    /// - Returns: Level from 1 to 12
    func calculateLevel(currentExp: Int) async -> Int

    /// Calculates XP threshold required to reach the next level
    ///
    /// - Parameter currentExp: Total accumulated experience
    /// - Returns: Total XP needed for next level, or 0 if at max level (12)
    func expToNextLevel(currentExp: Int) async -> Int

    /// Calculates progress within current level as a percentage
    ///
    /// - Parameter currentExp: Total accumulated experience
    /// - Returns: Progress from 0.0 to 1.0, returns 1.0 at max level
    func expProgress(currentExp: Int) async -> Double

    /// Calculates farming skill level from total skill experience
    ///
    /// Formula: `max(1, min(12, exp / 50))`
    ///
    /// Applicable to: Foraging, Fishing, Mining
    ///
    /// - Parameter exp: Total accumulated skill experience
    /// - Returns: Skill level from 1 to 12
    func farmingLevel(exp: Int) async -> Int

    /// Calculates progress within current farming skill level as a percentage
    ///
    /// - Parameter exp: Total accumulated skill experience
    /// - Returns: Progress from 0.0 to 1.0, returns 1.0 at max level
    func farmingProgress(exp: Int) async -> Double
}

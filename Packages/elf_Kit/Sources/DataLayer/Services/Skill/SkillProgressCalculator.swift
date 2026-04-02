//
//  SkillProgressCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Service for calculating skill progress after gaining experience
///
/// Extracted from SkillProgressData static method to separate business logic from data models.
public protocol SkillProgressCalculator: Sendable {

    /// Calculates skill progress from current state and gained experience
    ///
    /// - Parameters:
    ///   - skillName: Name of the skill (e.g., "Fishing", "Foraging")
    ///   - currentExp: Total experience before gaining more
    ///   - expGained: Amount of experience gained
    ///   - expPerLevel: Experience required per level
    /// - Returns: A SkillProgressData instance with calculated progress
    func calculate(
        skillName: String,
        currentExp: Int,
        expGained: Int,
        expPerLevel: Int
    ) async -> SkillProgressData

    /// Calculates skill progress from gathered items using their tier XP values
    ///
    /// - Parameters:
    ///   - items: Array of gathered items
    ///   - skillName: Name of the skill (e.g., "Fishing", "Foraging")
    ///   - currentExp: Total experience before gaining more
    ///   - expPerLevel: Experience required per level
    /// - Returns: A SkillProgressData instance with calculated progress
    func calculateFromGathered<T: GatherableItem>(
        _ items: [T],
        skillName: String,
        currentExp: Int,
        expPerLevel: Int
    ) async -> SkillProgressData
}

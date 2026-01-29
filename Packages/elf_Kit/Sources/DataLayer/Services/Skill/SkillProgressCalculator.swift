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
    ///   - currentLevel: Current level before gaining experience
    ///   - currentExp: Total experience before gaining more
    ///   - expGained: Amount of experience gained
    ///   - expPerLevel: Experience required per level
    /// - Returns: A SkillProgressData instance with calculated progress
    func calculate(
        skillName: String,
        currentLevel: Int,
        currentExp: Int,
        expGained: Int,
        expPerLevel: Int
    ) -> SkillProgressData
}

extension SkillProgressCalculator {

    /// Calculates skill progress from gathered items using their tier XP values
    func calculateFromGathered<T: GatherableItem>(
        _ items: [T],
        skillName: String,
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) -> SkillProgressData {
        let expGained = items.reduce(0) { $0 + $1.tier.xpValue }
        return calculate(
            skillName: skillName,
            currentLevel: currentLevel,
            currentExp: currentExp,
            expGained: expGained,
            expPerLevel: expPerLevel
        )
    }
}

//
//  ElfSkillProgressCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Default implementation of skill progress calculation service
///
/// Calculates new level and experience values after gaining XP in a skill.
public final class ElfSkillProgressCalculator: SkillProgressCalculator {

    // MARK: - Initialization

    public init() {}

    // MARK: - SkillProgressCalculator

    public func calculate(
        skillName: String,
        currentExp: Int,
        expGained: Int,
        expPerLevel: Int
    ) async -> SkillProgressData {
        let currentLevel = max(1, currentExp / expPerLevel)
        let previousExpInLevel = currentExp % expPerLevel
        let newTotalExp = currentExp + expGained
        let newLevel = max(1, newTotalExp / expPerLevel)
        let newExpInLevel = newTotalExp % expPerLevel

        return SkillProgressData(
            skillName: skillName,
            experienceGained: expGained,
            previousLevel: currentLevel,
            previousExp: previousExpInLevel,
            previousExpToNext: expPerLevel,
            newLevel: newLevel,
            newExp: newExpInLevel,
            newExpToNext: expPerLevel
        )
    }

    public func calculateFromGathered<T: GatherableItem>(
        _ items: [T],
        skillName: String,
        currentExp: Int,
        expPerLevel: Int
    ) async -> SkillProgressData {
        let expGained = items.reduce(0) { $0 + $1.tier.xpValue }
        return await calculate(
            skillName: skillName,
            currentExp: currentExp,
            expGained: expGained,
            expPerLevel: expPerLevel
        )
    }
}

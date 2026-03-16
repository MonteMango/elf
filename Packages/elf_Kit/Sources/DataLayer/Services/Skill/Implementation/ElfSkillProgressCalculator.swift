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
        currentLevel: Int,
        currentExp: Int,
        expGained: Int,
        expPerLevel: Int
    ) -> SkillProgressData {
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
}

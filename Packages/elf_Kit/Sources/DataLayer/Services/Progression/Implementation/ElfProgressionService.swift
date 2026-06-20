//
//  ElfProgressionService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Default implementation of progression calculation service
///
/// **Character Progression**:
/// - Levels 1-12
/// - 100 XP per level
/// - Level = max(1, min(12, currentExp / 100))
///
/// **Farming Skills** (Foraging, Fishing, Mining):
/// - Levels 1-12
/// - 50 XP per level
/// - Level = max(1, min(12, exp / 50))
public final class ElfProgressionService: ProgressionService {

    // MARK: - Constants

    private let maxLevel = 12
    private let characterExpPerLevel = 100
    private let farmingExpPerLevel = 50

    // MARK: - Initialization

    public init() {}

    // MARK: - ProgressionService

    public func calculateLevel(currentExp: Int) -> Int {
        max(1, min(maxLevel, currentExp / characterExpPerLevel))
    }

    public func expToNextLevel(currentExp: Int) -> Int {
        let level = calculateLevel(currentExp: currentExp)
        guard level < maxLevel else { return 0 }
        return (level + 1) * characterExpPerLevel
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
        levelProgress(exp: currentExp, expPerLevel: characterExpPerLevel)
    }

    public func farmingLevel(exp: Int) -> Int {
        max(1, min(maxLevel, exp / farmingExpPerLevel))
    }

    public func farmingProgress(exp: Int) -> Double {
        levelProgress(exp: exp, expPerLevel: farmingExpPerLevel)
    }

    // MARK: - Private Helpers

    private func levelProgress(exp: Int, expPerLevel: Int) -> Double {
        let level = max(1, min(maxLevel, exp / expPerLevel))
        guard level < maxLevel else { return 1.0 }

        let levelStartXP = level <= 1 ? 0 : level * expPerLevel
        let levelEndXP = (level + 1) * expPerLevel

        return Double(exp - levelStartXP) / Double(levelEndXP - levelStartXP)
    }
}

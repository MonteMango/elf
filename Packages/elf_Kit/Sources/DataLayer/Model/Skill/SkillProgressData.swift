//
//  SkillProgressData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Generic model for skill progress, used for fishing, foraging, mining, battle XP, etc.
public struct SkillProgressData: Sendable, Equatable {
    public let skillName: String
    public let experienceGained: Int
    public let previousLevel: Int
    public let previousExp: Int
    public let previousExpToNext: Int
    public let newLevel: Int
    public let newExp: Int
    public let newExpToNext: Int

    public var didLevelUp: Bool {
        newLevel > previousLevel
    }

    public init(
        skillName: String,
        experienceGained: Int,
        previousLevel: Int,
        previousExp: Int,
        previousExpToNext: Int,
        newLevel: Int,
        newExp: Int,
        newExpToNext: Int
    ) {
        self.skillName = skillName
        self.experienceGained = experienceGained
        self.previousLevel = previousLevel
        self.previousExp = previousExp
        self.previousExpToNext = previousExpToNext
        self.newLevel = newLevel
        self.newExp = newExp
        self.newExpToNext = newExpToNext
    }
}

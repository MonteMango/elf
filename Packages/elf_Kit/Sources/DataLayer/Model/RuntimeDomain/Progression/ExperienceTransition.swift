//
//  ExperienceTransition.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// A before→after snapshot of a character's level/experience across an XP gain.
/// Drives the result-overlay XP bar animation. Built once by `ProgressionService`
/// so every flow (hunt, dungeon, …) shares the same level/exp-to-next bracket math
/// instead of re-deriving it per call site.
public struct ExperienceTransition: Sendable, Equatable {
    public let previousLevel: Int
    public let previousExp: Int
    public let previousExpToNext: Int
    public let newLevel: Int
    public let newExp: Int
    public let newExpToNext: Int

    public init(
        previousLevel: Int,
        previousExp: Int,
        previousExpToNext: Int,
        newLevel: Int,
        newExp: Int,
        newExpToNext: Int
    ) {
        self.previousLevel = previousLevel
        self.previousExp = previousExp
        self.previousExpToNext = previousExpToNext
        self.newLevel = newLevel
        self.newExp = newExp
        self.newExpToNext = newExpToNext
    }
}

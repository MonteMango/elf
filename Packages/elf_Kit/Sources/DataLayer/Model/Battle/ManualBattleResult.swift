//
//  ManualBattleResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import Foundation

/// Represents the complete result of a manual battle for UI display
/// Contains XP, drops, and level progress information for the result overlay
public struct ManualBattleResult: Sendable, Equatable {
    public let outcome: BattleOutcome
    public let experienceGained: Int
    public let drops: [DropItem]

    // For XP bar animation - state before battle
    public let previousLevel: Int16
    public let previousExp: Int
    public let previousExpToNext: Int

    // For XP bar animation - state after battle
    public let newLevel: Int16
    public let newExp: Int
    public let newExpToNext: Int

    /// Returns true if player leveled up during this battle
    public var didLevelUp: Bool {
        newLevel > previousLevel
    }

    /// Returns the number of levels gained
    public var levelsGained: Int {
        Int(newLevel - previousLevel)
    }

    public init(
        outcome: BattleOutcome,
        experienceGained: Int,
        drops: [DropItem],
        previousLevel: Int16,
        previousExp: Int,
        previousExpToNext: Int,
        newLevel: Int16,
        newExp: Int,
        newExpToNext: Int
    ) {
        self.outcome = outcome
        self.experienceGained = experienceGained
        self.drops = drops
        self.previousLevel = previousLevel
        self.previousExp = previousExp
        self.previousExpToNext = previousExpToNext
        self.newLevel = newLevel
        self.newExp = newExp
        self.newExpToNext = newExpToNext
    }
}

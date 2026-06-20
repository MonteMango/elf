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

    /// Raw hunt rewards for applying to game state (materials, weapon/armor drops)
    public let huntRewards: HuntRewards?

    // For XP bar animation - state before battle
    public let previousLevel: Int
    public let previousExp: Int
    public let previousExpToNext: Int

    // For XP bar animation - state after battle
    public let newLevel: Int
    public let newExp: Int
    public let newExpToNext: Int

    /// Returns true if player leveled up during this battle
    public var didLevelUp: Bool {
        newLevel > previousLevel
    }

    /// Returns the number of levels gained
    public var levelsGained: Int {
        newLevel - previousLevel
    }

    public init(
        outcome: BattleOutcome,
        experienceGained: Int,
        drops: [DropItem],
        huntRewards: HuntRewards? = nil,
        previousLevel: Int,
        previousExp: Int,
        previousExpToNext: Int,
        newLevel: Int,
        newExp: Int,
        newExpToNext: Int
    ) {
        self.outcome = outcome
        self.experienceGained = experienceGained
        self.drops = drops
        self.huntRewards = huntRewards
        self.previousLevel = previousLevel
        self.previousExp = previousExp
        self.previousExpToNext = previousExpToNext
        self.newLevel = newLevel
        self.newExp = newExp
        self.newExpToNext = newExpToNext
    }

    /// Convenience initializer that fills the XP-bar fields from an
    /// `ExperienceTransition` (built by `ProgressionService`). Keeps the
    /// before→after level/exp math in one place instead of at each call site.
    public init(
        outcome: BattleOutcome,
        experienceGained: Int,
        drops: [DropItem],
        huntRewards: HuntRewards? = nil,
        transition: ExperienceTransition
    ) {
        self.init(
            outcome: outcome,
            experienceGained: experienceGained,
            drops: drops,
            huntRewards: huntRewards,
            previousLevel: transition.previousLevel,
            previousExp: transition.previousExp,
            previousExpToNext: transition.previousExpToNext,
            newLevel: transition.newLevel,
            newExp: transition.newExp,
            newExpToNext: transition.newExpToNext
        )
    }
}

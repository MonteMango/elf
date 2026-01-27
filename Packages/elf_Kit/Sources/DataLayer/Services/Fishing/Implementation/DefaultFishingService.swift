//
//  DefaultFishingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class DefaultFishingService: FishingService {

    // MARK: - Constants

    private let maxCatch = 4

    // MARK: - Initialization

    public init() {}

    // MARK: - FishingService

    public func performFishing(
        areaId: String,
        availableFish: [Fish],
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) -> FishingResult {
        // Sort fish by tier ascending (rarest first: tier 1 -> 4)
        let sortedFish = availableFish.sorted { $0.tier < $1.tier }

        // Roll for each fish
        var caughtFish: [Fish] = []

        for fish in sortedFish {
            guard caughtFish.count < maxCatch else { break }

            let roll = Double.random(in: 0..<1)
            if roll < fish.baseCatchChance {
                caughtFish.append(fish)
            }
        }

        // Calculate fishing XP gained: (5 - tier) * 5 per fish
        // Tier 1 (legendary) = 20 XP, Tier 4 (common) = 5 XP
        let expGained = caughtFish.reduce(0) { total, fish in
            total + (5 - fish.tier) * 5
        }

        // Calculate skill progress
        let skillProgress = calculateSkillProgress(
            currentLevel: currentLevel,
            currentExp: currentExp,
            expGained: expGained,
            expPerLevel: expPerLevel
        )

        return FishingResult(
            caughtFish: caughtFish,
            skillProgress: skillProgress
        )
    }

    // MARK: - Private Helpers

    private func calculateSkillProgress(
        currentLevel: Int,
        currentExp: Int,
        expGained: Int,
        expPerLevel: Int
    ) -> SkillProgressData {
        let previousExpInLevel = currentExp % expPerLevel
        let newTotalExp = currentExp + expGained
        let newLevel = newTotalExp / expPerLevel
        let newExpInLevel = newTotalExp % expPerLevel

        return SkillProgressData(
            skillName: "Fishing",
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

// MARK: - Sendable Conformance
// Thread-safe: Stateless class with no mutable stored properties.
extension DefaultFishingService: Sendable {}

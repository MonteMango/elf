//
//  HuntService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

// MARK: - HuntService

/// Service for managing hunt encounters and calculating rewards
public protocol HuntService: Sendable {

    /// Get all available monsters for a specific world and level
    /// - Parameters:
    ///   - world: The world type (upper, middle, lower)
    ///   - level: The level within the world (1, 2, or 3)
    /// - Returns: Array of available monsters
    func getAvailableMonsters(world: WorldType, level: Int) -> [Monster]

    /// Select a random monster for a hunt encounter
    /// - Parameters:
    ///   - world: The world type (upper, middle, lower)
    ///   - level: The level within the world (1, 2, or 3)
    /// - Returns: A random monster if available, nil otherwise
    func selectRandomMonster(world: WorldType, level: Int) -> Monster?

    /// Calculate rewards for defeating a monster
    /// Based on the monster's expReward and drops configuration
    /// - Parameter monster: The defeated monster
    /// - Returns: Calculated rewards including XP, materials, and potential equipment
    func calculateRewards(for monster: Monster) -> HuntRewards
}

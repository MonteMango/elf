//
//  FarmActivityService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Unified service for all farm activities (fishing, foraging, mining)
@MainActor
public protocol FarmActivityService: AnyObject, Sendable {

    /// Perform the specified activity and calculate results
    /// - Parameters:
    ///   - activity: The farm activity to perform
    ///   - currentLevel: Player's current skill level for this activity
    ///   - currentExp: Player's current experience for this activity
    ///   - expPerLevel: Experience required per level
    /// - Returns: FarmActivityResult with gathered items and skill progress
    func perform(
        activity: FarmActivity,
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) -> FarmActivityResult

    /// Get available items for the activity (fish, herbs, minerals)
    /// - Parameter activity: The farm activity
    /// - Returns: Array of items that can be obtained
    func getAvailableItems(for activity: FarmActivity) -> [FarmActivityItem]

    /// Get skill info for a specific activity and player
    /// - Parameters:
    ///   - activity: The farm activity
    ///   - player: The player's ElfInfo
    /// - Returns: FarmSkillInfo with current skill state
    func getSkillInfo(for activity: FarmActivity, player: ElfInfo) -> FarmSkillInfo

    /// Apply the result to game state (add items to inventory, add XP)
    /// - Parameters:
    ///   - result: The farm activity result to apply
    ///   - gameService: The game service to update
    func applyResult(_ result: FarmActivityResult, to gameService: any GameStateService)
}

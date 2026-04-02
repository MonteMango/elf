//
//  FarmActivityService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Unified service for all farm activities (fishing, foraging, mining)
public protocol FarmActivityService: Sendable {

    /// Perform the specified activity and calculate results
    /// - Parameters:
    ///   - activity: The farm activity to perform
    ///   - currentExp: Player's current experience for this activity
    ///   - expPerLevel: Experience required per level
    /// - Returns: FarmActivityResult with gathered items and skill progress
    func perform(
        activity: FarmActivity,
        currentExp: Int,
        expPerLevel: Int
    ) async -> FarmActivityResult

    /// Get available items for the activity (fish, herbs, minerals)
    /// - Parameter activity: The farm activity
    /// - Returns: Array of items that can be obtained
    func getAvailableItems(for activity: FarmActivity) async -> [FarmActivityItem]

    /// Get skill info for a specific activity and player
    /// - Parameters:
    ///   - activity: The farm activity
    ///   - player: The player's ElfInfo
    /// - Returns: FarmSkillInfo with current skill state
    func getSkillInfo(for activity: FarmActivity, player: ElfInfo) async -> FarmSkillInfo

}

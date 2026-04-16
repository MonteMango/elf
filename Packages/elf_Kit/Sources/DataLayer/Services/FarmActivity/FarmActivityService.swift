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
    ) -> FarmActivityResult

    /// Get available items for the activity (fish, herbs, minerals)
    /// - Parameter activity: The farm activity
    /// - Returns: Array of items that can be obtained
    func getAvailableItems(for activity: FarmActivity) -> [FarmActivityItem]

    /// Get skill info for a specific activity and exp value.
    /// - Parameters:
    ///   - activity: The farm activity
    ///   - exp: The player's current experience for this activity
    /// - Returns: FarmSkillInfo with current skill state
    func getSkillInfo(for activity: FarmActivity, exp: Int) -> FarmSkillInfo

}

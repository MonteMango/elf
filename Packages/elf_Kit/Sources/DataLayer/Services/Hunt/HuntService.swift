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

    /// Calculate rewards for defeating a monster
    /// Based on the monster's expReward and drops configuration
    /// - Parameter monster: The defeated monster
    /// - Returns: Calculated rewards including XP, materials, and potential equipment
    func calculateRewards(for monster: Monster) async -> HuntRewards
}

//
//  GatheringEngine.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Unified engine for gathering items in farm activities.
/// Used by FishingService, ForagingService, and MiningService.
public protocol GatheringEngine: Sendable {

    /// Perform gathering with random chance based on item's baseSuccessChance.
    ///
    /// - Parameters:
    ///   - items: Available items to gather from
    ///   - maxCount: Maximum items to gather
    /// - Returns: Array of successfully gathered items
    func gather<Item: GatherableItem>(from items: [Item], maxCount: Int) async -> [Item]
}

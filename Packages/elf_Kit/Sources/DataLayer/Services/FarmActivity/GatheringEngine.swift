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

    /// Perform gathering with random chance based on each item's `baseSuccessChance`.
    ///
    /// Implementations decide the max number of items to gather and the source of
    /// randomness; both are configured at construction.
    ///
    /// - Parameter items: Available items to gather from.
    /// - Returns: Array of successfully gathered items (subset of `items`).
    func gather<Item: GatherableItem>(from items: [Item]) -> [Item]
}

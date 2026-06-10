//
//  GatherableItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Protocol for items that can be gathered through farm activities (fishing, foraging, mining)
public protocol GatherableItem: Codable, Sendable, Identifiable, Hashable {
    var title: String { get }
    var imageName: String { get }
    var description: String { get }
    var tier: ItemTier { get }

    /// Base chance to successfully gather this item (0.0 - 1.0)
    var baseSuccessChance: Double { get }
}

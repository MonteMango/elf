//
//  ItemAttributeAggregator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Aggregates attributes from equipped items
public protocol ItemAttributeAggregator: Sendable {

    /// Get aggregated attributes from a list of item IDs
    ///
    /// - Parameter itemIds: Array of catalog item IDs
    /// - Returns: Combined attributes from all items
    func getAllItemsAttributes(for itemIds: [ItemID]) -> HeroAttributes
}

//
//  RobeSaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.12.25.
//

import Foundation

/// DTO for robe persistence.
/// Stores instance ID and base item ID.
public struct RobeSaveData: Sendable, Equatable, Codable {
    /// Unique instance ID
    public let id: OwnedItemID

    /// Base item ID from HeroItems (robes)
    public let itemId: ItemID

    /// Create from ElfRobeItem
    public init(from elfRobe: ElfRobeItem) {
        self.id = elfRobe.id
        self.itemId = elfRobe.item.id
    }

    /// Convert to ElfRobeItem using items repository
    public func toElfRobeItem(using repository: ItemsRepository) -> ElfRobeItem? {
        guard let item = repository.getHeroItem(itemId) as? RobeItem else {
            return nil
        }
        return ElfRobeItem(id: id, item: item)
    }
}

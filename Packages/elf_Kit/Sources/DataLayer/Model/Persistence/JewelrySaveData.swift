//
//  JewelrySaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.12.25.
//

import Foundation

/// DTO for saving jewelry items to disk.
public struct JewelrySaveData: Codable, Sendable, Equatable {
    /// Unique instance ID
    public let id: UUID

    /// Base item ID from HeroItems.json
    public let itemId: UUID

    /// Create from ElfJewelryItem
    public init(from jewelry: ElfJewelryItem) {
        self.id = jewelry.id
        self.itemId = jewelry.item.id
    }

    /// Convert to ElfJewelryItem using items repository
    public func toElfJewelryItem(using repository: ItemsRepository) async -> ElfJewelryItem? {
        guard let item = await repository.getHeroItem(itemId) as? JewelryItem else {
            return nil
        }
        return ElfJewelryItem(id: id, item: item)
    }
}

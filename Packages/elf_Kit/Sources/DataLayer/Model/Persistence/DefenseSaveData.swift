//
//  DefenseSaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.12.25.
//

import Foundation

/// DTO for saving defense items (armor) to disk.
public struct DefenseSaveData: Codable, Sendable, Equatable {
    /// Unique instance ID
    public let id: UUID

    /// Base item ID from HeroItems.json
    public let itemId: UUID

    /// Create from ElfDefenseItem
    public init(from defense: ElfDefenseItem) {
        self.id = defense.id
        self.itemId = defense.item.id
    }

    /// Convert to ElfDefenseItem using items repository
    public func toElfDefenseItem(using repository: ItemsRepository) async -> ElfDefenseItem? {
        guard let item = await repository.getHeroItem(itemId) as? DefenseItem else {
            return nil
        }
        return ElfDefenseItem(id: id, item: item)
    }
}

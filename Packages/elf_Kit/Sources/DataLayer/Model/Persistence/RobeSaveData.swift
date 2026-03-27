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
    public let id: UUID

    /// Base item ID from HeroItems (robes)
    public let itemId: UUID

    /// Create from ElfRobeItem
    public init(from elfRobe: ElfRobeItem) {
        self.id = elfRobe.id
        self.itemId = elfRobe.item.id
    }

    /// Convert to ElfRobeItem using items repository
    public func toElfRobeItem(using repository: ItemsRepository) async -> ElfRobeItem? {
        guard let item = await repository.getHeroItem(itemId) as? RobeItem else {
            return nil
        }
        return ElfRobeItem(id: id, item: item)
    }
}

//
//  ShieldSaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.12.25.
//

import Foundation

/// DTO for shield persistence.
/// Stores instance ID and base item ID.
public struct ShieldSaveData: Sendable, Equatable, Codable {
    /// Unique instance ID
    public let id: UUID

    /// Base item ID from HeroItems (shields)
    public let itemId: UUID

    /// Create from ElfShieldItem
    public init(from elfShield: ElfShieldItem) {
        self.id = elfShield.id
        self.itemId = elfShield.item.id
    }

    /// Convert to ElfShieldItem using items repository
    public func toElfShieldItem(using repository: ItemsRepository) async -> ElfShieldItem? {
        guard let item = await repository.getHeroItem(itemId) as? ShieldItem else {
            return nil
        }
        return ElfShieldItem(id: id, item: item)
    }
}

//
//  WeaponSaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.12.25.
//

import Foundation

/// DTO for weapon persistence.
/// Stores instance ID, base item ID, and enchantment level.
public struct WeaponSaveData: Sendable, Equatable, Codable {
    /// Unique instance ID
    public let id: UUID

    /// Base item ID from HeroItems (weapons)
    public let itemId: UUID

    /// Enchantment level of this weapon instance
    public let enchantLevel: Int

    /// Create from ElfWeaponItem
    public init(from elfWeapon: ElfWeaponItem) {
        self.id = elfWeapon.id
        self.itemId = elfWeapon.item.id
        self.enchantLevel = elfWeapon.enchantLevel
    }

    /// Convert to ElfWeaponItem using items repository
    public func toElfWeaponItem(using repository: ItemsRepository) async -> ElfWeaponItem? {
        guard let item = await repository.getHeroItem(itemId) as? WeaponItem else {
            return nil
        }
        return ElfWeaponItem(id: id, item: item, enchantLevel: enchantLevel)
    }
}

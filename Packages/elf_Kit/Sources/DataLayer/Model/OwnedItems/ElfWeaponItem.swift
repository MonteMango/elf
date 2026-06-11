//
//  ElfWeaponItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 27.05.25.
//

import Foundation

// MARK: - Sendable Conformance
// Thread-safe: All stored properties are immutable (let) after initialization.
// `id` is UUID, `enchantLevel` is Int (value types), `item` is Item protocol but implementations are reference-immutable.
public final class ElfWeaponItem: ElfItem, Hashable, Equatable, @unchecked Sendable {
    public let id: OwnedItemID
    public let item: Item

    public let enchantLevel: Int

    public init(id: OwnedItemID, item: Item, enchantLevel: Int) {
        self.id = id
        self.item = item
        self.enchantLevel = enchantLevel
    }

    public init(weaponItem: WeaponItem) {
        self.id = OwnedItemID()
        self.item = weaponItem
        self.enchantLevel = 0
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: ElfWeaponItem, rhs: ElfWeaponItem) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

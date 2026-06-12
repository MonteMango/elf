//
//  ElfWeaponItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 27.05.25.
//

import Foundation

// MARK: - Sendable Conformance
// Checked Sendable: `final class` whose only stored properties are immutable (`let`)
// and themselves Sendable (`id: OwnedItemID`, `item: Item`, `enchantLevel: Int`). Verified by the compiler.
public final class ElfWeaponItem: ElfItem, Hashable, Equatable, Sendable {
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

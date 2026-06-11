//
//  ItemsRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public protocol ItemsRepository: Sendable {

    /// Get a hero item by its catalog id.
    func getHeroItem(_ id: ItemID) -> Item?

    /// Get all items of a specific type.
    func getItems(for type: HeroItemType) -> [Item]

    /// Returns the armor slot the given base item id belongs to, if it is an armor piece.
    /// Slots are determined by which category the item was loaded into (helmets / gloves / shoes /
    /// upperBodies / bottomBodies) — NOT by `protectParts`, which overlap across slots.
    func armorSlot(for itemId: ItemID) -> ArmorSlot?
}

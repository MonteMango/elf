//
//  DropItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import Foundation

/// Represents a dropped item for UI display after battle
public struct DropItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let itemType: DropItemType
    public let name: String
    public let icon: String
    public let rarity: ItemRarity
    public let quantity: Int

    public init(
        id: UUID = UUID(),
        itemType: DropItemType,
        name: String,
        icon: String,
        rarity: ItemRarity,
        quantity: Int = 1
    ) {
        self.id = id
        self.itemType = itemType
        self.name = name
        self.icon = icon
        self.rarity = rarity
        self.quantity = quantity
    }
}

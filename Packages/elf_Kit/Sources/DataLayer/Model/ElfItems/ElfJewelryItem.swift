//
//  ElfJewelryItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 27.05.25.
//

import Foundation

public final class ElfJewelryItem: ElfItem, Hashable, Equatable {
    public let id: UUID
    public let item: Item

    public init(id: UUID, item: Item) {
        self.id = id
        self.item = item
    }

    public init(jewelryItem: JewelryItem) {
        self.id = UUID()
        self.item = jewelryItem
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: ElfJewelryItem, rhs: ElfJewelryItem) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

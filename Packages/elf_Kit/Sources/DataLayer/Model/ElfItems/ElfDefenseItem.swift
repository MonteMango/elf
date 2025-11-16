//
//  ElfDefenseItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 27.05.25.
//

import Foundation

public final class ElfDefenseItem: ElfItem, Hashable, Equatable {
    public let id: UUID
    public let item: Item

    public let rune: Int? = nil

    public init(id: UUID, item: Item) {
        self.id = id
        self.item = item
    }

    public init(defenseItem: DefenseItem) {
        self.id = UUID()
        self.item = defenseItem
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: ElfDefenseItem, rhs: ElfDefenseItem) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

//
//  ElfShieldItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 27.05.25.
//

import Foundation

public final class ElfShieldItem: ElfItem, Hashable, Equatable, @unchecked Sendable {
    public let id: UUID
    public let item: Item

    public let rune: Int? = nil

    public init(id: UUID, item: Item) {
        self.id = id
        self.item = item
    }

    public init(shieldItem: ShieldItem) {
        self.id = UUID()
        self.item = shieldItem
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: ElfShieldItem, rhs: ElfShieldItem) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

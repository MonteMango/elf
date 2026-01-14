//
//  ElfRobeItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 27.05.25.
//

import Foundation

// MARK: - Sendable Conformance
// Thread-safe: All stored properties are immutable (let) after initialization.
// `id` is UUID (value type), `item` is Item protocol but implementations are reference-immutable.
public final class ElfRobeItem: ElfItem, Hashable, Equatable, @unchecked Sendable {
    public let id: UUID
    public let item: Item

    public init(id: UUID, item: Item) {
        self.id = id
        self.item = item
    }

    public init(robeItem: RobeItem) {
        self.id = UUID()
        self.item = robeItem
    }

    // MARK: - Hashable & Equatable

    public static func == (lhs: ElfRobeItem, rhs: ElfRobeItem) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

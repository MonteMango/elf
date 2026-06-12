//
//  ElfRobeItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 27.05.25.
//

import Foundation

// MARK: - Sendable Conformance
// Checked Sendable: `final class` whose only stored properties are immutable (`let`)
// and themselves Sendable (`id: OwnedItemID`, `item: Item`). Verified by the compiler.
public final class ElfRobeItem: ElfItem, Hashable, Equatable, Sendable {
    public let id: OwnedItemID
    public let item: Item

    public init(id: OwnedItemID, item: Item) {
        self.id = id
        self.item = item
    }

    public init(robeItem: RobeItem) {
        self.id = OwnedItemID()
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

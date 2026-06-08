//
//  FakeItemsRepository.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Foundation
@testable import elf_Kit

/// Shared in-memory `ItemsRepository` stub. Seed `items[id] = …` for
/// `getHeroItem`; `heroItems` defaults to an empty catalog and is mutable for
/// tests that need to seed it. Replaces the per-file copies that had to be
/// hand-edited in lockstep whenever the protocol changed.
final class FakeItemsRepository: ItemsRepository, @unchecked Sendable {
    nonisolated(unsafe) var items: [UUID: Item] = [:]
    nonisolated(unsafe) var heroItems: HeroItems = HeroItems(
        version: "1.0.0-test",
        helmets: [], gloves: [], shoes: [],
        upperBodies: [], bottomBodies: [], robes: [],
        weapons: [], shields: [],
        rings: [], necklaces: [], earrings: []
    )

    func getHeroItem(_ id: UUID) -> Item? { items[id] }
    func getItems(for type: HeroItemType) -> [Item] { [] }
    func armorSlot(for itemId: UUID) -> ArmorSlot? { nil }
}

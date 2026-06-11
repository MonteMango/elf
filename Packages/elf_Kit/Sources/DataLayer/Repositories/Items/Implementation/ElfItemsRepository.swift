//
//  ElfItemsRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class ElfItemsRepository: ItemsRepository {

    private let heroItems: HeroItems
    private let lookup: [ItemID: Item]
    private let armorSlotLookup: [ItemID: ArmorSlot]

    public init(heroItems: HeroItems) {
        self.heroItems = heroItems

        var lookup: [ItemID: Item] = [:]
        func index<T: Item>(_ items: [T]) {
            items.forEach { lookup[$0.id] = $0 }
        }

        index(heroItems.helmets)
        index(heroItems.gloves)
        index(heroItems.shoes)
        index(heroItems.upperBodies)
        index(heroItems.bottomBodies)
        index(heroItems.robes)
        index(heroItems.weapons)
        index(heroItems.shields)
        index(heroItems.rings)
        index(heroItems.necklaces)
        index(heroItems.earrings)

        self.lookup = lookup

        // Slot is driven by the JSON category, not by protectParts — the latter overlap
        // (e.g. an upper-body piece can list `head` to grant head defense without being a helmet).
        var armorSlotLookup: [ItemID: ArmorSlot] = [:]
        heroItems.helmets.forEach { armorSlotLookup[$0.id] = .helmet }
        heroItems.gloves.forEach { armorSlotLookup[$0.id] = .gloves }
        heroItems.shoes.forEach { armorSlotLookup[$0.id] = .shoes }
        heroItems.upperBodies.forEach { armorSlotLookup[$0.id] = .upperBody }
        heroItems.bottomBodies.forEach { armorSlotLookup[$0.id] = .bottomBody }
        self.armorSlotLookup = armorSlotLookup
    }

    public func getHeroItem(_ id: ItemID) -> Item? {
        lookup[id]
    }

    public func armorSlot(for itemId: ItemID) -> ArmorSlot? {
        armorSlotLookup[itemId]
    }

    public func getItems(for type: HeroItemType) -> [Item] {
        switch type {
        case .helmet:
            return heroItems.helmets
        case .gloves:
            return heroItems.gloves
        case .shoes:
            return heroItems.shoes
        case .upperBody:
            return heroItems.upperBodies
        case .bottomBody:
            return heroItems.bottomBodies
        case .shirt:
            return heroItems.robes
        case .weapons:
            return heroItems.weapons
        case .shields:
            return heroItems.shields + heroItems.weapons.filter { $0.handUse == .oneHand }
        case .ring:
            return heroItems.rings
        case .necklace:
            return heroItems.necklaces
        case .earrings:
            return heroItems.earrings
        }
    }
}

//
//  ElfItemsRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class ElfItemsRepository: ItemsRepository {

    private let heroItems: HeroItems
    private let lookup: [UUID: Item]

    public init(heroItems: HeroItems) {
        self.heroItems = heroItems

        var lookup: [UUID: Item] = [:]
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
    }

    public func getHeroItem(_ id: UUID) async -> Item? {
        lookup[id]
    }

    public func getItems(for type: HeroItemType) async -> [Item] {
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
            return heroItems.shields + heroItems.weapons.filter { $0.handUse == .secondary }
        case .ring:
            return heroItems.rings
        case .necklace:
            return heroItems.necklaces
        case .earrings:
            return heroItems.earrings
        }
    }
}

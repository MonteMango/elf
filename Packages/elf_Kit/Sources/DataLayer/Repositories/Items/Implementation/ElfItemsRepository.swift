//
//  ElfItemsRepository.swift
//
//
//  Created by Vitalii Lytvynov on 24.09.24.
//

import Foundation

public final class ElfItemsRepository: ItemsRepository {

    // MARK: Properties

    private let _heroItems: HeroItems
    private let heroItemLookup: [UUID: Item]

    // MARK: Initialization

    public init(dataLoader: DataLoader = ElfDataLoader()) {
        // Load data synchronously from bundle (fast operation)
        // If file not found (e.g., in previews), use empty data
        let data: Data
        do {
            data = try dataLoader.loadHeroItemsData()
        } catch {
            // For previews or when file not available, create minimal mock data
            print("⚠️ Warning: Could not load HeroItems.json, using empty data: \(error)")
            data = Self.createEmptyHeroItemsJSON()
        }

        // Decode JSON
        let heroItems: HeroItems
        do {
            heroItems = try JSONDecoder().decode(HeroItems.self, from: data)
        } catch {
            // If decoding fails (e.g., invalid JSON in tests), use empty HeroItems
            print("⚠️ Warning: Failed to decode hero items, using empty fallback: \(error)")
            do {
                heroItems = try JSONDecoder().decode(HeroItems.self, from: Self.createEmptyHeroItemsJSON())
            } catch {
                // This should never happen with our hardcoded empty JSON
                fatalError("Failed to decode even fallback HeroItems: \(error)")
            }
        }

        self._heroItems = heroItems

        // Build the lookup cache
        var lookup: [UUID: Item] = [:]

        func index<T: Item>(_ items: [T]) {
            items.forEach { lookup[$0.id] = $0 }
        }

        index(_heroItems.helmets)
        index(_heroItems.gloves)
        index(_heroItems.shoes)
        index(_heroItems.upperBodies)
        index(_heroItems.bottomBodies)
        index(_heroItems.robes)
        index(_heroItems.weapons)
        index(_heroItems.shields)
        index(_heroItems.rings)
        index(_heroItems.necklaces)
        index(_heroItems.earrings)

        self.heroItemLookup = lookup
    }

    // MARK: ItemsRepository

    public var heroItems: HeroItems {
        return _heroItems
    }

    public func getHeroItem(_ id: UUID) -> Item? {
        return heroItemLookup[id]
    }

    public func getItems(for type: HeroItemType) -> [Item] {
        switch type {
        case .helmet:
            return _heroItems.helmets
        case .gloves:
            return _heroItems.gloves
        case .shoes:
            return _heroItems.shoes
        case .upperBody:
            return _heroItems.upperBodies
        case .bottomBody:
            return _heroItems.bottomBodies
        case .shirt:
            return _heroItems.robes
        case .weapons:
            return _heroItems.weapons
        case .shields:
            // Shields include both shield items and weapons with secondary hand use
            return _heroItems.shields + _heroItems.weapons.filter { $0.handUse == .secondary }
        case .ring:
            return _heroItems.rings
        case .necklace:
            return _heroItems.necklaces
        case .earrings:
            return _heroItems.earrings
        }
    }

    // MARK: - Private Helpers

    private static func createEmptyHeroItemsJSON() -> Data {
        let emptyJSON = """
        {
            "version": "1.0.0-empty",
            "helmets": [],
            "gloves": [],
            "shoes": [],
            "upperBodies": [],
            "bottomBodies": [],
            "robes": [],
            "weapons": [],
            "shields": [],
            "rings": [],
            "necklaces": [],
            "earrings": []
        }
        """
        return emptyJSON.data(using: .utf8)!
    }
}

// MARK: - Sendable Conformance
extension ElfItemsRepository: @unchecked Sendable {}

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
        do {
            self._heroItems = try JSONDecoder().decode(HeroItems.self, from: data)
        } catch {
            // This should never happen with our fallback JSON, but handle gracefully
            print("❌ Error: Failed to decode hero items: \(error)")
            fatalError("Failed to decode hero items: \(error)")
        }

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

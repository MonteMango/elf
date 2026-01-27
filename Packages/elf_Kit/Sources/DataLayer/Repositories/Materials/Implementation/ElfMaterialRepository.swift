//
//  ElfMaterialRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

public final class ElfMaterialRepository: MaterialRepository {

    // MARK: - Properties

    private let _materialsData: MaterialsData
    private let materialLookup: [UUID: Material]
    private let fishRepository: (any FishRepository)?

    // MARK: - Initialization

    public init(
        dataLoader: DataLoader = ElfDataLoader(),
        fishRepository: (any FishRepository)? = nil
    ) {
        self.fishRepository = fishRepository

        // Load data synchronously from bundle
        let data: Data
        do {
            data = try dataLoader.loadMaterialsData()
        } catch {
            print("⚠️ Warning: Could not load Materials.json, using empty data: \(error)")
            data = Self.createEmptyMaterialsJSON()
        }

        // Decode JSON
        let materialsData: MaterialsData
        do {
            materialsData = try JSONDecoder().decode(MaterialsData.self, from: data)
        } catch {
            print("⚠️ Warning: Failed to decode materials, using empty fallback: \(error)")
            materialsData = MaterialsData()
        }

        self._materialsData = materialsData

        // Build lookup cache
        var lookup: [UUID: Material] = [:]
        for material in materialsData.monstersDrop {
            lookup[material.id] = material
        }
        self.materialLookup = lookup
    }

    // MARK: - MaterialRepository

    public var materialsData: MaterialsData {
        return _materialsData
    }

    public func getMaterial(id: UUID) -> Material? {
        // First, look up in materials
        if let material = materialLookup[id] {
            return material
        }

        // If not found, try fish repository
        if let fish = fishRepository?.getFish(id: id) {
            return Material(
                id: fish.id,
                title: fish.title,
                imageName: fish.imageName,
                category: .fish,
                description: fish.description
            )
        }

        return nil
    }

    public func getMaterialCategory(id: UUID) -> MaterialSubcategory? {
        if let material = materialLookup[id] {
            return material.category
        }

        if fishRepository?.getFish(id: id) != nil {
            return .fish
        }

        return nil
    }

    // MARK: - Private Helpers

    private static func createEmptyMaterialsJSON() -> Data {
        let emptyJSON = """
        {
            "version": "1.0-empty",
            "monsters_drop": []
        }
        """
        return Data(emptyJSON.utf8)
    }
}

// MARK: - Sendable Conformance
// Thread-safe: All stored properties are immutable (let) after initialization.
// `_materialsData` is a value type, `materialLookup` is an immutable dictionary of value types.
// `fishRepository` is optional and Sendable.
extension ElfMaterialRepository: @unchecked Sendable {}

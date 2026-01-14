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

    // MARK: - Initialization

    public init(dataLoader: DataLoader = ElfDataLoader()) {
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
        return materialLookup[id]
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
extension ElfMaterialRepository: @unchecked Sendable {}

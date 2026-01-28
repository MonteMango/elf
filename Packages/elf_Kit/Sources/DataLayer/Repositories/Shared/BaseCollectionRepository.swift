//
//  BaseCollectionRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation
import os.log

/// Base class for repositories that manage collections of gatherable items.
/// Provides common lookup functionality for items and effects.
public class BaseCollectionRepository<DataType: CollectionData>: @unchecked Sendable {

    // MARK: - Properties

    private let _data: DataType
    private let itemLookup: [DataType.Item.ID: DataType.Item]
    private let effectLookup: [String: EffectDefinition]

    // MARK: - Public Accessors

    public var data: DataType { _data }

    // MARK: - Initialization

    public init(data: DataType) {
        self._data = data

        // Build item lookup cache
        var iLookup: [DataType.Item.ID: DataType.Item] = [:]
        for item in data.items {
            iLookup[item.id] = item
        }
        self.itemLookup = iLookup

        // Build effect lookup cache (keyed by effectType)
        var eLookup: [String: EffectDefinition] = [:]
        for effect in data.effects {
            eLookup[effect.effectType] = effect
        }
        self.effectLookup = eLookup
    }

    /// Convenience initializer that handles load → decode → fallback logic.
    /// - Parameters:
    ///   - loadData: Closure that loads raw JSON data
    ///   - log: OSLog instance for error logging
    ///   - resourceName: Name of the resource for logging purposes
    public convenience init(
        loadData: () throws -> Data,
        log: OSLog,
        resourceName: String
    ) {
        let rawData: Data
        do {
            rawData = try loadData()
        } catch {
            os_log("Could not load %{public}@, using empty data: %{public}@",
                   log: log, type: .error, resourceName, error.localizedDescription)
            rawData = Data("{}".utf8)
        }

        let decoded: DataType
        do {
            decoded = try JSONDecoder().decode(DataType.self, from: rawData)
        } catch {
            os_log("Failed to decode %{public}@, using empty fallback: %{public}@",
                   log: log, type: .error, resourceName, error.localizedDescription)
            decoded = DataType.empty
        }

        self.init(data: decoded)
    }

    // MARK: - Item Access

    /// Get item by ID
    public func getItem(id: DataType.Item.ID) -> DataType.Item? {
        itemLookup[id]
    }

    /// Get all items
    public func getAllItems() -> [DataType.Item] {
        _data.items
    }

    // MARK: - Effect Access

    /// Get effect definition by effect type string
    public func getEffectDefinition(_ id: String) -> EffectDefinition? {
        effectLookup[id]
    }
}

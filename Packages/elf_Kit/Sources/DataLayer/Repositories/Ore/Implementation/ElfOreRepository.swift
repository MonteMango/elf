//
//  ElfOreRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation
import os.log

public final class ElfOreRepository: OreRepository {

    // MARK: - Properties

    private static let log = OSLog(subsystem: "com.elfy.kit", category: "OreRepository")
    private let base: BaseCollectionRepository<OreData>

    // MARK: - Initialization

    public init(dataLoader: DataLoader = ElfDataLoader()) {
        self.base = BaseCollectionRepository(
            loadData: dataLoader.loadOresData,
            log: Self.log,
            resourceName: "Ores.json"
        )
    }

    // MARK: - OreRepository

    public var oreData: OreData {
        base.data
    }

    public func getOre(id: OreID) -> Ore? {
        base.getItem(id: id)
    }

    public func getAllOres() -> [Ore] {
        base.getAllItems()
    }

    public func getOresForArea(_ areaId: String) -> [Ore] {
        guard let area = base.data.areas[areaId] else {
            return []
        }
        return area.ores.compactMap { oreId in
            base.getItem(id: oreId)
        }
    }

    public func getEffectDefinition(_ id: String) -> EffectDefinition? {
        base.getEffectDefinition(id)
    }
}

// MARK: - Sendable Conformance
// Thread-safe: All stored properties are immutable (let) after initialization.
// `base` contains immutable dictionaries of value types.
extension ElfOreRepository: @unchecked Sendable {}

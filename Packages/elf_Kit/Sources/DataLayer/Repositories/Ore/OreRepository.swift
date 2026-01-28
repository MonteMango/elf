//
//  OreRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public protocol OreRepository: Sendable {
    /// All loaded ore data
    var oreData: OreData { get }

    /// Get an ore by its ID
    /// - Parameter id: Ore's unique identifier
    /// - Returns: Ore if found, nil otherwise
    func getOre(id: OreID) -> Ore?

    /// Get all available ores
    /// - Returns: Array of all ores
    func getAllOres() -> [Ore]

    /// Get ores available in a specific area
    /// - Parameter areaId: Area identifier (e.g., "crystal_cave")
    /// - Returns: Array of ores available in that area
    func getOresForArea(_ areaId: String) -> [Ore]

    /// Get effect definition by its ID
    /// - Parameter id: Effect identifier (e.g., "hardness", "purity")
    /// - Returns: EffectDefinition if found, nil otherwise
    func getEffectDefinition(_ id: String) -> EffectDefinition?
}

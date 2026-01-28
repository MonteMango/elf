//
//  HerbRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public protocol HerbRepository: Sendable {
    /// All loaded herb data
    var herbData: HerbData { get }

    /// Get a herb by its ID
    /// - Parameter id: Herb's unique identifier
    /// - Returns: Herb if found, nil otherwise
    func getHerb(id: HerbID) -> Herb?

    /// Get all available herbs
    /// - Returns: Array of all herbs
    func getAllHerbs() -> [Herb]

    /// Get herbs available in a specific area
    /// - Parameter areaId: Area identifier (e.g., "forest_glade")
    /// - Returns: Array of herbs available in that area
    func getHerbsForArea(_ areaId: String) -> [Herb]

    /// Get effect definition by its ID
    /// - Parameter id: Effect identifier (e.g., "healing", "mana")
    /// - Returns: EffectDefinition if found, nil otherwise
    func getEffectDefinition(_ id: String) -> EffectDefinition?
}

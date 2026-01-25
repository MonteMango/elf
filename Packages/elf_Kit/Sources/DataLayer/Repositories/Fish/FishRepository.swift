//
//  FishRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 20.01.26.
//

import Foundation

public protocol FishRepository: Sendable {
    /// All loaded fish data
    var fishData: FishData { get }

    /// Get a fish by its ID
    /// - Parameter id: Fish's unique identifier
    /// - Returns: Fish if found, nil otherwise
    func getFish(id: UUID) -> Fish?

    /// Get all available fish
    /// - Returns: Array of all fish
    func getAllFish() -> [Fish]

    /// Get fish available in a specific area
    /// - Parameter areaId: Area identifier (e.g., "forest_pond")
    /// - Returns: Array of fish available in that area
    func getFishForArea(_ areaId: String) -> [Fish]

    /// Get effect definition by its ID
    /// - Parameter id: Effect identifier (e.g., "arcane", "flame")
    /// - Returns: EffectDefinition if found, nil otherwise
    func getEffectDefinition(_ id: String) -> EffectDefinition?
}

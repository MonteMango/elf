//
//  OreRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public protocol OreRepository: Sendable {
    /// Get an ore by its ID
    /// - Parameter id: Ore's unique identifier
    /// - Returns: Ore if found, nil otherwise
    func getOre(id: OreID) -> Ore?

    /// Get all available ores
    /// - Returns: Array of all ores
    func getAllOres() -> [Ore]

}

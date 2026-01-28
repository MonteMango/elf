//
//  MiningService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - MiningService

/// Service for managing mining mechanics and calculating mine results
public protocol MiningService: Sendable {

    /// Perform mining and calculate results
    /// - Parameters:
    ///   - areaId: The mining area identifier (e.g., "crystal_cave")
    ///   - availableOres: Array of ores available in the area
    ///   - currentLevel: Player's current mining level
    ///   - currentExp: Player's current mining experience
    ///   - expPerLevel: Experience required per level
    /// - Returns: MiningResult with mined ores and skill progress
    func performMining(
        areaId: String,
        availableOres: [Ore],
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) -> MiningResult
}

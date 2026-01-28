//
//  ForagingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - ForagingService

/// Service for managing foraging mechanics and calculating gather results
public protocol ForagingService: Sendable {

    /// Perform foraging and calculate results
    /// - Parameters:
    ///   - areaId: The foraging area identifier (e.g., "forest_glade")
    ///   - availableHerbs: Array of herbs available in the area
    ///   - currentLevel: Player's current foraging level
    ///   - currentExp: Player's current foraging experience
    ///   - expPerLevel: Experience required per level
    /// - Returns: ForagingResult with gathered herbs and skill progress
    func performForaging(
        areaId: String,
        availableHerbs: [Herb],
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) -> ForagingResult
}

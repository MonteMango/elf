//
//  FishingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - FishingService

/// Service for managing fishing mechanics and calculating catch results
public protocol FishingService: Sendable {

    /// Perform fishing and calculate results
    /// - Parameters:
    ///   - areaId: The fishing area identifier (e.g., "forest_pond")
    ///   - availableFish: Array of fish available in the area
    ///   - currentLevel: Player's current fishing level
    ///   - currentExp: Player's current fishing experience
    ///   - expPerLevel: Experience required per level
    /// - Returns: FishingResult with caught fish and skill progress
    func performFishing(
        areaId: String,
        availableFish: [Fish],
        currentLevel: Int,
        currentExp: Int,
        expPerLevel: Int
    ) -> FishingResult
}

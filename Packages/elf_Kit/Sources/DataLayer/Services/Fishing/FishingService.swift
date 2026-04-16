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
    ///   - availableFish: Array of fish available in the area
    ///   - currentExp: Player's current fishing experience
    ///   - expPerLevel: Experience required per level
    /// - Returns: FishingResult with caught fish and skill progress
    func performFishing(
        availableFish: [Fish],
        currentExp: Int,
        expPerLevel: Int
    ) -> FishingResult
}

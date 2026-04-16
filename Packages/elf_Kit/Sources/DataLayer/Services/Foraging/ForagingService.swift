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
    ///   - availableHerbs: Array of herbs available in the area
    ///   - currentExp: Player's current foraging experience
    ///   - expPerLevel: Experience required per level
    /// - Returns: ForagingResult with gathered herbs and skill progress
    func performForaging(
        availableHerbs: [Herb],
        currentExp: Int,
        expPerLevel: Int
    ) -> ForagingResult
}

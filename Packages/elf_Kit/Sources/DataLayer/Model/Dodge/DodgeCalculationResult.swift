//
//  DodgeCalculationResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import Foundation

/// Result of a dodge chance calculation using triangular distribution
///
/// **Stage 1**: Select dodge chance from triangular distribution (minimum has highest weight)
/// **Stage 2**: Roll to check if dodge succeeds with the selected chance
///
/// This result contains all intermediate values for logging and debugging purposes.
public struct DodgeCalculationResult: Sendable {

    // MARK: - Stage 1: Select Dodge Chance

    /// The distribution used for selecting dodge chance
    public let distribution: DodgeDistribution

    /// The dodge chance selected from triangular distribution
    /// Minimum value has highest probability, maximum has lowest
    /// Can be negative or zero (results in auto-fail)
    /// Can be 100+ (results in auto-success)
    public let selectedChance: Int16

    // MARK: - Stage 2: Check Dodge Success

    /// Random roll (1-100) used to check dodge success in stage 2
    /// `nil` if dodge was auto-fail (chance <= 0) or auto-success (chance >= 100)
    public let stage2Roll: Int?

    /// Final result: did the dodge succeed?
    /// - `true`: Dodge successful (no damage taken)
    /// - `false`: Dodge failed (proceed to damage calculation)
    public let success: Bool

    // MARK: - Initialization

    public init(
        distribution: DodgeDistribution,
        selectedChance: Int16,
        stage2Roll: Int?,
        success: Bool
    ) {
        self.distribution = distribution
        self.selectedChance = selectedChance
        self.stage2Roll = stage2Roll
        self.success = success
    }
}

//
//  DodgeCalculationResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import Foundation

/// Result of a two-stage dodge chance calculation
///
/// **Stage 1**: Select dodge chance from distribution (60% for minimum, 40% for range)
/// **Stage 2**: Roll to check if dodge succeeds with the selected chance
///
/// This result contains all intermediate values for logging and debugging purposes.
public struct DodgeCalculationResult: Sendable {

    // MARK: - Stage 1: Select Dodge Chance

    /// The distribution used for selecting dodge chance
    public let distribution: DodgeDistribution

    /// Random roll (1-100) used to select dodge chance in stage 1
    /// - 1-60: Select minimum chance (60% probability)
    /// - 61-100: Select from range using triangular distribution (40% total)
    public let stage1Roll: Int

    /// The dodge chance selected in stage 1
    /// This value will be used in stage 2 to determine dodge success
    /// Can be negative (results in auto-fail)
    /// Can be 100+ (results in auto-success)
    public let selectedChance: Int16

    // MARK: - Stage 2: Check Dodge Success

    /// Random roll (1-100) used to check dodge success in stage 2
    /// `nil` if dodge was auto-fail (negative chance) or auto-success (100+ chance)
    public let stage2Roll: Int?

    /// Final result: did the dodge succeed?
    /// - `true`: Dodge successful (no damage taken)
    /// - `false`: Dodge failed (proceed to damage calculation)
    public let success: Bool

    // MARK: - Initialization

    public init(
        distribution: DodgeDistribution,
        stage1Roll: Int,
        selectedChance: Int16,
        stage2Roll: Int?,
        success: Bool
    ) {
        self.distribution = distribution
        self.stage1Roll = stage1Roll
        self.selectedChance = selectedChance
        self.stage2Roll = stage2Roll
        self.success = success
    }
}

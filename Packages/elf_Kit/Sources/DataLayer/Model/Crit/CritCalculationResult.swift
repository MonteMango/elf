//
//  CritCalculationResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Result of a three-stage critical hit calculation
///
/// **Stage 1**: Select crit chance from distribution (40% for minimum, 60% for range)
/// **Stage 2**: Roll to check if crit succeeds with the selected chance
/// **Stage 3**: If crit succeeded, select damage multiplier (1.25/1.5/2.0/3.0)
///
/// This result contains all intermediate values for logging and debugging purposes.
public struct CritCalculationResult: Sendable {

    // MARK: - Stage 1: Select Crit Chance

    /// The distribution used for selecting crit chance
    public let distribution: CritDistribution

    /// Random roll (1-100) used to select crit chance in stage 1
    /// - 1-40: Select minimum chance (40% probability)
    /// - 41-100: Select from range using triangular distribution (60% total)
    public let stage1Roll: Int

    /// The crit chance selected in stage 1
    /// This value will be used in stage 2 to determine crit success
    /// Can be negative (results in auto-fail)
    /// Can be 100+ (results in auto-success)
    public let selectedChance: Int16

    // MARK: - Stage 2: Check Crit Success

    /// Random roll (1-100) used to check crit success in stage 2
    /// `nil` if crit was auto-fail (negative chance) or auto-success (100+ chance)
    public let stage2Roll: Int?

    /// Did the critical hit succeed?
    /// - `true`: Critical hit! Proceed to stage 3 for multiplier selection
    /// - `false`: Normal hit (multiplier = 1.0)
    public let success: Bool

    // MARK: - Stage 3: Select Damage Multiplier

    /// The multiplier distribution used in stage 3 (only if success = true)
    public let multiplierDistribution: CritMultiplierDistribution

    /// Random roll used to select multiplier in stage 3
    /// `nil` if crit failed (success = false)
    /// Range depends on totalWeight (typically 1-10)
    public let multiplierRoll: Int?

    /// The final damage multiplier
    /// - `1.0` if crit failed
    /// - `1.25 / 1.5 / 2.0 / 3.0` if crit succeeded (selected from weighted distribution)
    public let selectedMultiplier: Double

    // MARK: - Initialization

    public init(
        distribution: CritDistribution,
        stage1Roll: Int,
        selectedChance: Int16,
        stage2Roll: Int?,
        success: Bool,
        multiplierDistribution: CritMultiplierDistribution,
        multiplierRoll: Int?,
        selectedMultiplier: Double
    ) {
        self.distribution = distribution
        self.stage1Roll = stage1Roll
        self.selectedChance = selectedChance
        self.stage2Roll = stage2Roll
        self.success = success
        self.multiplierDistribution = multiplierDistribution
        self.multiplierRoll = multiplierRoll
        self.selectedMultiplier = selectedMultiplier
    }
}

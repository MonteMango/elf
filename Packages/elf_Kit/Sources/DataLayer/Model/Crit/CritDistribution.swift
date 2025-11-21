//
//  CritDistribution.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Represents a triangular probability distribution for critical hit chance calculation
///
/// The distribution uses triangular weights where:
/// - **Minimum** has the highest probability
/// - **Maximum** has the lowest probability
/// - Weights decrease linearly: [n, n-1, n-2, ..., 2, 1]
///
/// Range includes all values from minimum to maximum (inclusive).
/// Negative or zero values result in auto-fail when checked.
public struct CritDistribution: Equatable, Sendable {

    /// The minimum crit chance (power - instinct)
    /// Can be negative (which results in auto-fail in stage 2)
    public let minimumChance: Int16

    /// The maximum crit chance (power, capped at 100)
    public let maximumChance: Int16

    /// Array of all crit chance values in range minimum...maximum
    /// Includes both minimum and maximum
    public let rangeValues: [Int16]

    /// Triangular weights for rangeValues
    /// Weight decreases linearly: [n, n-1, n-2, ..., 2, 1]
    /// where n = rangeValues.count
    /// First value (minimum) has highest weight
    public let rangeWeights: [Int]

    // MARK: - Initialization

    public init(
        minimumChance: Int16,
        maximumChance: Int16,
        rangeValues: [Int16],
        rangeWeights: [Int]
    ) {
        self.minimumChance = minimumChance
        self.maximumChance = maximumChance
        self.rangeValues = rangeValues
        self.rangeWeights = rangeWeights
    }

    // MARK: - Computed Properties

    /// Returns true if there are values in the distribution
    public var hasRange: Bool {
        return !rangeValues.isEmpty
    }

    /// Total number of possible crit chance values
    public var totalValues: Int {
        return rangeValues.count
    }
}

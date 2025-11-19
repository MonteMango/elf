//
//  DodgeDistribution.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 18.11.25.
//

import Foundation

/// Represents a two-stage probability distribution for dodge chance calculation
///
/// The distribution splits into two parts:
/// - **Minimum chance** (60% probability): The base dodge chance (agility - instinct)
/// - **Range values** (40% total): Additional chances from (minimum + 1) to maximum (agility, cap at 100)
///
/// The range uses triangular distribution where weights decrease linearly:
/// - Highest weight for values closest to minimum
/// - Lowest weight for values closest to maximum
public struct DodgeDistribution: Equatable, Sendable {

    /// The minimum dodge chance (agility - instinct)
    /// Has 60% probability of being selected in stage 1
    /// Can be negative (which results in auto-fail in stage 2)
    public let minimumChance: Int16

    /// The maximum dodge chance (agility, capped at 100)
    public let maximumChance: Int16

    /// Array of dodge chance values in range (minimum + 1)...maximum
    /// Empty if minimum >= maximum
    /// These values share 40% probability using triangular distribution
    public let rangeValues: [Int16]

    /// Triangular weights for rangeValues (40% total probability)
    /// Weight decreases linearly: [n, n-1, n-2, ..., 2, 1]
    /// where n = rangeValues.count
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

    /// Returns true if there is a range to distribute probabilities over
    /// Returns false if minimum >= maximum (use only minimum chance)
    public var hasRange: Bool {
        return !rangeValues.isEmpty
    }

    /// Total number of possible dodge chance values (minimum + range)
    public var totalValues: Int {
        return 1 + rangeValues.count
    }
}

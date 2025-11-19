//
//  CritMultiplierDistribution.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Fixed probability distribution for critical hit damage multipliers
///
/// Defines weighted random selection of crit multipliers:
/// - `1.25x` → 40% (weight 4)
/// - `1.5x` → 30% (weight 3)
/// - `2.0x` → 20% (weight 2)
/// - `3.0x` → 10% (weight 1)
///
/// This distribution is used in stage 3 of crit calculation (after successful crit)
public struct CritMultiplierDistribution: Equatable, Sendable {

    /// Available multiplier values
    public let values: [Double]

    /// Weights for each multiplier value
    /// Total weight = 10 (4+3+2+1)
    public let weights: [Int]

    // MARK: - Initialization

    /// Creates the standard crit multiplier distribution
    /// - values: [1.25, 1.5, 2.0, 3.0]
    /// - weights: [4, 3, 2, 1] representing 40%, 30%, 20%, 10%
    public init() {
        self.values = [1.25, 1.5, 2.0, 3.0]
        self.weights = [4, 3, 2, 1]
    }

    // MARK: - Computed Properties

    /// Total weight sum (should be 10)
    public var totalWeight: Int {
        return weights.reduce(0, +)
    }

    /// Number of available multipliers
    public var count: Int {
        return values.count
    }
}

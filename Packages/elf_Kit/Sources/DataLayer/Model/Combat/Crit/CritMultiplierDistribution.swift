//
//  CritMultiplierDistribution.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Probability distribution for critical hit damage multipliers.
///
/// Defines weighted random selection of crit multipliers. The actual values
/// and weights live in `GameMechanicsConstants.critMultiplierValues` /
/// `critMultiplierWeights` — change them there to tune the mean. The
/// distribution is fixed at calculation time — defender stats no longer
/// skew it (the previous agility-decreases-multiplier coupling was removed
/// so each attribute keeps a single role).
public struct CritMultiplierDistribution: Equatable, Sendable {

    /// Available multiplier values
    public let values: [Double]

    /// Weights for each multiplier value
    public let weights: [Int]

    // MARK: - Initialization

    /// Creates the standard crit multiplier distribution from GameMechanicsConstants
    public init() {
        self.values = GameMechanicsConstants.critMultiplierValues
        self.weights = GameMechanicsConstants.critMultiplierWeights
    }

    /// Creates a custom crit multiplier distribution with specified values and weights
    ///
    /// - Parameters:
    ///   - values: Multiplier values (must match weights count)
    ///   - weights: Weights for each multiplier (higher = more likely)
    public init(values: [Double], weights: [Int]) {
        self.values = values
        self.weights = weights
    }

    // MARK: - Computed Properties

    /// Total weight sum
    public var totalWeight: Int {
        return weights.reduce(0, +)
    }

}

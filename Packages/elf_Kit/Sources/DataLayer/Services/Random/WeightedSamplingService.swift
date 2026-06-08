//
//  WeightedSamplingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

/// Generic weighted random sampling. Picks one element from `values` where
/// each index's probability is `weights[i] / sum(weights)`.
///
/// The generator is passed in (`using:`) so the whole combat chain shares
/// **one** generator per battle — resolved once at the battle boundary and
/// threaded down, never read from `@Dependency` in the per-roll hot loop.
public protocol WeightedSamplingService: Sendable {

    /// Returns `nil` only if `values` is empty, the two arrays are different
    /// lengths, or the sum of weights is zero.
    func sample<T>(values: [T], weights: [Int], using generator: WithRandomNumberGenerator) -> T?
}

public extension WeightedSamplingService {
    /// Convenience for call sites that don't thread a per-battle generator
    /// (production single battles, unit tests). Resolves
    /// `\.withRandomNumberGenerator` **once** per call and delegates.
    func sample<T>(values: [T], weights: [Int]) -> T? {
        @Dependency(\.withRandomNumberGenerator) var generator
        return sample(values: values, weights: weights, using: generator)
    }
}

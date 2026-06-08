//
//  ElfWeightedSamplingService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

public struct ElfWeightedSamplingService: WeightedSamplingService {

    public init() {}

    public func sample<T>(values: [T], weights: [Int], using generator: WithRandomNumberGenerator) -> T? {
        guard values.count == weights.count, !values.isEmpty else { return nil }
        let total = weights.reduce(0, +)
        guard total > 0 else { return nil }

        // The roll happens inside the generator closure; the (possibly
        // non-Sendable) `values` are indexed outside it, so `T` needs no
        // Sendable bound.
        let roll = generator { Int.random(in: 0..<total, using: &$0) }
        var cumulative = 0
        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if roll < cumulative {
                return values[index]
            }
        }
        return values.last
    }
}

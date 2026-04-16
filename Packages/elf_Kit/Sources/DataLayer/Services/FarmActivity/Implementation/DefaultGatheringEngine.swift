//
//  DefaultGatheringEngine.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class DefaultGatheringEngine: GatheringEngine {

    // MARK: - Configuration

    private let maxCount: Int
    private let nextRoll: @Sendable () -> Double

    // MARK: - Initialization

    /// - Parameters:
    ///   - maxCount: Maximum items gathered per call. Defaults to 4.
    ///   - nextRoll: Source of randomness. Each call returns a value in `0..<1`.
    ///     Defaults to the system random generator. Tests inject a deterministic stub.
    public init(
        maxCount: Int = 4,
        nextRoll: @escaping @Sendable () -> Double = { Double.random(in: 0..<1) }
    ) {
        self.maxCount = maxCount
        self.nextRoll = nextRoll
    }

    // MARK: - GatheringEngine

    /// Algorithm:
    /// 1. Sort items by `tier` ascending (rarest first: tier 1 → tier 4)
    /// 2. For each item, roll random chance against `baseSuccessChance`
    /// 3. Collect up to `maxCount` items
    public func gather<Item: GatherableItem>(from items: [Item]) -> [Item] {
        let sortedItems = items.sorted { $0.tier < $1.tier }
        var result: [Item] = []

        for item in sortedItems {
            guard result.count < maxCount else { break }

            if nextRoll() < item.baseSuccessChance {
                result.append(item)
            }
        }

        return result
    }
}

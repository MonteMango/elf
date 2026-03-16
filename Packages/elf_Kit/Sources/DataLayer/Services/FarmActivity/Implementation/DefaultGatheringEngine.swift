//
//  DefaultGatheringEngine.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class DefaultGatheringEngine: GatheringEngine, Sendable {

    /// Default maximum items to gather per activity
    public static let defaultMaxCount = 4

    public init() {}

    /// Perform gathering with random chance based on item's baseSuccessChance.
    ///
    /// Algorithm:
    /// 1. Sort items by tier ascending (rarest first: tier 1 → tier 4)
    /// 2. For each item, roll random chance against baseSuccessChance
    /// 3. Collect up to maxCount items
    public func gather<Item: GatherableItem>(
        from items: [Item],
        maxCount: Int = DefaultGatheringEngine.defaultMaxCount
    ) -> [Item] {
        let sortedItems = items.sorted { $0.tier < $1.tier }
        var result: [Item] = []

        for item in sortedItems {
            guard result.count < maxCount else { break }

            let roll = Double.random(in: 0..<1)
            if roll < item.baseSuccessChance {
                result.append(item)
            }
        }

        return result
    }
}

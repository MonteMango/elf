//
//  BattleStatisticsAggregator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Service for aggregating battle statistics from multiple battle results
///
/// Extracted from AggregatedBattleStatistics static method to separate business logic from data models.
public protocol BattleStatisticsAggregator: Sendable {

    /// Creates aggregated statistics from multiple battle results for a specific bot
    ///
    /// - Parameters:
    ///   - results: Array of battle results to aggregate
    ///   - forBot1: If true, aggregate stats for bot1; if false, for bot2
    /// - Returns: Aggregated statistics with averages and totals
    func aggregate(from results: [BattleResult], forBot1: Bool) -> AggregatedBattleStatistics
}

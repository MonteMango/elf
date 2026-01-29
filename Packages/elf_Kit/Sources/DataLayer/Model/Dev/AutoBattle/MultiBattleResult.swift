//
//  MultiBattleResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Result of running multiple battles between the same two bots
///
/// Contains:
/// - Win/draw counts and rates
/// - All individual battle results
/// - Aggregated statistics for both bots
public struct MultiBattleResult: Sendable {

    // MARK: - Configuration

    /// Total number of battles run
    public let totalBattles: Int

    /// Bot1 level
    public let bot1Level: Int

    /// Bot2 level
    public let bot2Level: Int

    // MARK: - Win/Draw Counts

    /// Number of battles won by bot1
    public let bot1Wins: Int

    /// Number of battles won by bot2
    public let bot2Wins: Int

    /// Number of draws (both HP <= 0)
    public let draws: Int

    // MARK: - Results

    /// All individual battle results
    public let battleResults: [BattleResult]

    /// Aggregated statistics for bot1 across all battles
    public let bot1AggregatedStats: AggregatedBattleStatistics

    /// Aggregated statistics for bot2 across all battles
    public let bot2AggregatedStats: AggregatedBattleStatistics

    // MARK: - Initialization

    public init(
        totalBattles: Int,
        bot1Level: Int,
        bot2Level: Int,
        bot1Wins: Int,
        bot2Wins: Int,
        draws: Int,
        battleResults: [BattleResult],
        bot1AggregatedStats: AggregatedBattleStatistics,
        bot2AggregatedStats: AggregatedBattleStatistics
    ) {
        self.totalBattles = totalBattles
        self.bot1Level = bot1Level
        self.bot2Level = bot2Level
        self.bot1Wins = bot1Wins
        self.bot2Wins = bot2Wins
        self.draws = draws
        self.battleResults = battleResults
        self.bot1AggregatedStats = bot1AggregatedStats
        self.bot2AggregatedStats = bot2AggregatedStats
    }

    // MARK: - Computed Properties

    /// Win rate for bot1 (0.0 - 1.0)
    public var bot1WinRate: Double {
        guard totalBattles > 0 else { return 0.0 }
        return Double(bot1Wins) / Double(totalBattles)
    }

    /// Win rate for bot2 (0.0 - 1.0)
    public var bot2WinRate: Double {
        guard totalBattles > 0 else { return 0.0 }
        return Double(bot2Wins) / Double(totalBattles)
    }

    /// Draw rate (0.0 - 1.0)
    public var drawRate: Double {
        guard totalBattles > 0 else { return 0.0 }
        return Double(draws) / Double(totalBattles)
    }
}

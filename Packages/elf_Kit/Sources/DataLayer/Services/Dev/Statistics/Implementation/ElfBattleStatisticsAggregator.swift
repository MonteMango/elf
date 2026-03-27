//
//  ElfBattleStatisticsAggregator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Default implementation of battle statistics aggregation service
///
/// Aggregates statistics from multiple BattleResult instances into a single
/// AggregatedBattleStatistics with averages and totals.
public final class ElfBattleStatisticsAggregator: BattleStatisticsAggregator {

    // MARK: - Initialization

    public init() {}

    // MARK: - BattleStatisticsAggregator

    public func aggregate(from results: [BattleResult], forBot1: Bool) async -> AggregatedBattleStatistics {
        let battleCount = results.count
        guard battleCount > 0 else {
            return AggregatedBattleStatistics(
                averageRounds: 0, totalRounds: 0,
                averageCritRate: 0, averageCritHits: 0, totalCritAttempts: 0, totalCritSuccesses: 0,
                totalCritBlockBreaks: 0, averageCritBlockBreakRate: 0, totalCritsDodged: 0, averageCritsDodgedRate: 0,
                averageDodgeRate: 0, averageDodges: 0, totalDodgeAttempts: 0, totalDodgeSuccesses: 0,
                averageTotalDamage: 0, averageDamagePerRound: 0, totalDamage: 0,
                averageStrengthDamage: 0, averageStrengthDamagePerRound: 0, totalStrengthDamage: 0
            )
        }

        // Round statistics
        let totalRounds = results.reduce(0) { $0 + $1.totalRounds }
        let averageRounds = Double(totalRounds) / Double(battleCount)

        // Crit statistics
        let totalCritAttempts: Int
        let totalCritSuccesses: Int
        let totalCritBlockBreaks: Int
        let totalCritsDodged: Int
        if forBot1 {
            totalCritAttempts = results.reduce(0) { $0 + $1.statistics.bot1CritAttempts }
            totalCritSuccesses = results.reduce(0) { $0 + $1.statistics.bot1CritSuccesses }
            totalCritBlockBreaks = results.reduce(0) { $0 + $1.statistics.bot1CritBlockBreaks }
            totalCritsDodged = results.reduce(0) { $0 + $1.statistics.bot1CritsDodged }
        } else {
            totalCritAttempts = results.reduce(0) { $0 + $1.statistics.bot2CritAttempts }
            totalCritSuccesses = results.reduce(0) { $0 + $1.statistics.bot2CritSuccesses }
            totalCritBlockBreaks = results.reduce(0) { $0 + $1.statistics.bot2CritBlockBreaks }
            totalCritsDodged = results.reduce(0) { $0 + $1.statistics.bot2CritsDodged }
        }
        let averageCritRate = totalCritAttempts > 0 ? Double(totalCritSuccesses) / Double(totalCritAttempts) : 0.0
        let averageCritHits = Double(totalCritSuccesses) / Double(battleCount)
        let averageCritBlockBreakRate = totalCritSuccesses > 0 ? Double(totalCritBlockBreaks) / Double(totalCritSuccesses) : 0.0
        let averageCritsDodgedRate = totalCritSuccesses > 0 ? Double(totalCritsDodged) / Double(totalCritSuccesses) : 0.0

        // Dodge statistics
        let totalDodgeAttempts: Int
        let totalDodgeSuccesses: Int
        if forBot1 {
            totalDodgeAttempts = results.reduce(0) { $0 + $1.statistics.bot1DodgeAttempts }
            totalDodgeSuccesses = results.reduce(0) { $0 + $1.statistics.bot1DodgeSuccesses }
        } else {
            totalDodgeAttempts = results.reduce(0) { $0 + $1.statistics.bot2DodgeAttempts }
            totalDodgeSuccesses = results.reduce(0) { $0 + $1.statistics.bot2DodgeSuccesses }
        }
        let averageDodgeRate = totalDodgeAttempts > 0 ? Double(totalDodgeSuccesses) / Double(totalDodgeAttempts) : 0.0
        let averageDodges = Double(totalDodgeSuccesses) / Double(battleCount)

        // Damage statistics
        let totalDamage: Int
        let totalStrengthDamage: Int
        if forBot1 {
            totalDamage = results.reduce(0) { $0 + $1.statistics.bot1TotalDamage }
            totalStrengthDamage = results.reduce(0) { $0 + $1.statistics.bot1TotalStrengthDamage }
        } else {
            totalDamage = results.reduce(0) { $0 + $1.statistics.bot2TotalDamage }
            totalStrengthDamage = results.reduce(0) { $0 + $1.statistics.bot2TotalStrengthDamage }
        }
        let averageTotalDamage = Double(totalDamage) / Double(battleCount)
        let averageDamagePerRound = totalRounds > 0 ? Double(totalDamage) / Double(totalRounds) : 0.0
        let averageStrengthDamage = Double(totalStrengthDamage) / Double(battleCount)
        let averageStrengthDamagePerRound = totalRounds > 0 ? Double(totalStrengthDamage) / Double(totalRounds) : 0.0

        return AggregatedBattleStatistics(
            averageRounds: averageRounds,
            totalRounds: totalRounds,
            averageCritRate: averageCritRate,
            averageCritHits: averageCritHits,
            totalCritAttempts: totalCritAttempts,
            totalCritSuccesses: totalCritSuccesses,
            totalCritBlockBreaks: totalCritBlockBreaks,
            averageCritBlockBreakRate: averageCritBlockBreakRate,
            totalCritsDodged: totalCritsDodged,
            averageCritsDodgedRate: averageCritsDodgedRate,
            averageDodgeRate: averageDodgeRate,
            averageDodges: averageDodges,
            totalDodgeAttempts: totalDodgeAttempts,
            totalDodgeSuccesses: totalDodgeSuccesses,
            averageTotalDamage: averageTotalDamage,
            averageDamagePerRound: averageDamagePerRound,
            totalDamage: totalDamage,
            averageStrengthDamage: averageStrengthDamage,
            averageStrengthDamagePerRound: averageStrengthDamagePerRound,
            totalStrengthDamage: totalStrengthDamage
        )
    }
}

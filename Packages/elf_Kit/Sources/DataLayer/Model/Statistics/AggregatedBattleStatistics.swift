//
//  AggregatedBattleStatistics.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Aggregated statistics for one bot across multiple battles
///
/// Contains averages and totals for:
/// - Round counts
/// - Crit statistics (rate, hits, block breaks)
/// - Dodge statistics (rate, dodges, dodges that avoid crits)
/// - Damage statistics (total, per round, strength)
public struct AggregatedBattleStatistics: Sendable {

    // MARK: - Round Statistics

    /// Average number of rounds per battle
    public let averageRounds: Double

    /// Total rounds across all battles
    public let totalRounds: Int

    // MARK: - Crit Statistics

    /// Average crit rate (0.0 - 1.0)
    public let averageCritRate: Double

    /// Average number of successful crits per battle
    public let averageCritHits: Double

    /// Total crit attempts across all battles
    public let totalCritAttempts: Int

    /// Total successful crits across all battles
    public let totalCritSuccesses: Int

    /// Total crit block breaks across all battles
    public let totalCritBlockBreaks: Int

    /// Average crit block break rate (0.0 - 1.0)
    public let averageCritBlockBreakRate: Double

    /// Total crits dodged across all battles
    public let totalCritsDodged: Int

    /// Average crits dodged rate (0.0 - 1.0)
    public let averageCritsDodgedRate: Double

    // MARK: - Dodge Statistics

    /// Average dodge rate (0.0 - 1.0)
    public let averageDodgeRate: Double

    /// Average number of successful dodges per battle
    public let averageDodges: Double

    /// Total dodge attempts across all battles
    public let totalDodgeAttempts: Int

    /// Total successful dodges across all battles
    public let totalDodgeSuccesses: Int

    // MARK: - Damage Statistics

    /// Average total damage per battle
    public let averageTotalDamage: Double

    /// Average damage per round
    public let averageDamagePerRound: Double

    /// Total damage across all battles
    public let totalDamage: Int

    // MARK: - Strength Damage Statistics

    /// Average strength damage per battle
    public let averageStrengthDamage: Double

    /// Average strength damage per round
    public let averageStrengthDamagePerRound: Double

    /// Total strength damage across all battles
    public let totalStrengthDamage: Int

    // MARK: - Initialization

    public init(
        averageRounds: Double,
        totalRounds: Int,
        averageCritRate: Double,
        averageCritHits: Double,
        totalCritAttempts: Int,
        totalCritSuccesses: Int,
        totalCritBlockBreaks: Int,
        averageCritBlockBreakRate: Double,
        totalCritsDodged: Int,
        averageCritsDodgedRate: Double,
        averageDodgeRate: Double,
        averageDodges: Double,
        totalDodgeAttempts: Int,
        totalDodgeSuccesses: Int,
        averageTotalDamage: Double,
        averageDamagePerRound: Double,
        totalDamage: Int,
        averageStrengthDamage: Double,
        averageStrengthDamagePerRound: Double,
        totalStrengthDamage: Int
    ) {
        self.averageRounds = averageRounds
        self.totalRounds = totalRounds
        self.averageCritRate = averageCritRate
        self.averageCritHits = averageCritHits
        self.totalCritAttempts = totalCritAttempts
        self.totalCritSuccesses = totalCritSuccesses
        self.totalCritBlockBreaks = totalCritBlockBreaks
        self.averageCritBlockBreakRate = averageCritBlockBreakRate
        self.totalCritsDodged = totalCritsDodged
        self.averageCritsDodgedRate = averageCritsDodgedRate
        self.averageDodgeRate = averageDodgeRate
        self.averageDodges = averageDodges
        self.totalDodgeAttempts = totalDodgeAttempts
        self.totalDodgeSuccesses = totalDodgeSuccesses
        self.averageTotalDamage = averageTotalDamage
        self.averageDamagePerRound = averageDamagePerRound
        self.totalDamage = totalDamage
        self.averageStrengthDamage = averageStrengthDamage
        self.averageStrengthDamagePerRound = averageStrengthDamagePerRound
        self.totalStrengthDamage = totalStrengthDamage
    }

    // MARK: - Static Factory

    /// Creates aggregated statistics from multiple battle results for a specific bot
    public static func aggregate(from results: [BattleResult], forBot1: Bool) -> AggregatedBattleStatistics {
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

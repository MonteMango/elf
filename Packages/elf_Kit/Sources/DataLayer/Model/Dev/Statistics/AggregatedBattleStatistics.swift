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
}

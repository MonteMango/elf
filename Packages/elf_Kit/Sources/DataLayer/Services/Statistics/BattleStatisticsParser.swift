//
//  BattleStatisticsParser.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Service for parsing combat results into battle statistics
///
/// Extracts crit, dodge, and damage statistics from PointStatus results.
/// Used by AutoBattleViewModel and MultiBattleViewModel to collect statistics.
public protocol BattleStatisticsParser: Sendable {

    /// Parse combat results to extract statistics for crits, dodges, and strength damage
    ///
    /// - Parameters:
    ///   - attackingPoints: Set of body parts being attacked
    ///   - defendingPoints: Set of body parts being defended
    ///   - results: Combat results for each body part
    ///   - attackerCritAttempts: Counter for attacker's crit attempts
    ///   - attackerCritSuccesses: Counter for attacker's successful crits
    ///   - attackerCritMultipliers: Dictionary of crit multiplier counts
    ///   - attackerCritBlockBreaks: Counter for crits that broke blocks
    ///   - attackerCritsDodged: Counter for crits that were dodged
    ///   - defenderDodgeAttempts: Counter for defender's dodge attempts
    ///   - defenderDodgeSuccesses: Counter for defender's successful dodges
    ///   - attackerStrengthDamage: Counter for attacker's strength damage
    func parseStatistics(
        attackingPoints: Set<BodyPart>,
        defendingPoints: Set<BodyPart>,
        results: [BodyPart: PointStatus],
        attackerCritAttempts: inout Int,
        attackerCritSuccesses: inout Int,
        attackerCritMultipliers: inout [Double: Int],
        attackerCritBlockBreaks: inout Int,
        attackerCritsDodged: inout Int,
        defenderDodgeAttempts: inout Int,
        defenderDodgeSuccesses: inout Int,
        attackerStrengthDamage: inout Int
    )
}

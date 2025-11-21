//
//  BattleStatistics.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Statistics collected during a battle for analysis and reporting
///
/// Tracks critical hits, dodges, damage distribution, and other combat metrics
/// for both combatants across all rounds.
public struct BattleStatistics: Sendable {

    // MARK: - Critical Hit Statistics

    /// Total number of crit attempts by bot1
    public let bot1CritAttempts: Int

    /// Number of successful crits by bot1
    public let bot1CritSuccesses: Int

    /// Distribution of crit multipliers used by bot1: [1.25: count, 1.5: count, 2.0: count, 3.0: count]
    public let bot1CritMultipliers: [Double: Int]

    /// Total number of crit attempts by bot2
    public let bot2CritAttempts: Int

    /// Number of successful crits by bot2
    public let bot2CritSuccesses: Int

    /// Distribution of crit multipliers used by bot2
    public let bot2CritMultipliers: [Double: Int]

    /// Number of crits that broke blocks by bot1 (critHit when defended)
    public let bot1CritBlockBreaks: Int

    /// Number of crits that broke blocks by bot2
    public let bot2CritBlockBreaks: Int

    /// Number of crits that were dodged from bot1
    public let bot1CritsDodged: Int

    /// Number of crits that were dodged from bot2
    public let bot2CritsDodged: Int

    // MARK: - Dodge Statistics

    /// Total number of dodge attempts by bot1
    public let bot1DodgeAttempts: Int

    /// Number of successful dodges by bot1
    public let bot1DodgeSuccesses: Int

    /// Total number of dodge attempts by bot2
    public let bot2DodgeAttempts: Int

    /// Number of successful dodges by bot2
    public let bot2DodgeSuccesses: Int

    // MARK: - Damage Statistics

    /// Total damage dealt by bot1 across all rounds
    public let bot1TotalDamage: Int

    /// Total damage dealt by bot2 across all rounds
    public let bot2TotalDamage: Int

    /// Damage dealt by bot1 per round: [roundNumber: damage]
    public let bot1DamagePerRound: [Int: Int]

    /// Damage dealt by bot2 per round: [roundNumber: damage]
    public let bot2DamagePerRound: [Int: Int]

    // MARK: - Strength Damage Statistics

    /// Total strength damage dealt by bot1
    public let bot1TotalStrengthDamage: Int

    /// Total strength damage dealt by bot2
    public let bot2TotalStrengthDamage: Int

    /// Strength damage dealt by bot1 per round: [roundNumber: strengthDamage]
    public let bot1StrengthDamagePerRound: [Int: Int]

    /// Strength damage dealt by bot2 per round: [roundNumber: strengthDamage]
    public let bot2StrengthDamagePerRound: [Int: Int]

    // MARK: - Initialization

    public init(
        bot1CritAttempts: Int,
        bot1CritSuccesses: Int,
        bot1CritMultipliers: [Double: Int],
        bot2CritAttempts: Int,
        bot2CritSuccesses: Int,
        bot2CritMultipliers: [Double: Int],
        bot1CritBlockBreaks: Int,
        bot2CritBlockBreaks: Int,
        bot1CritsDodged: Int,
        bot2CritsDodged: Int,
        bot1DodgeAttempts: Int,
        bot1DodgeSuccesses: Int,
        bot2DodgeAttempts: Int,
        bot2DodgeSuccesses: Int,
        bot1TotalDamage: Int,
        bot2TotalDamage: Int,
        bot1DamagePerRound: [Int: Int],
        bot2DamagePerRound: [Int: Int],
        bot1TotalStrengthDamage: Int,
        bot2TotalStrengthDamage: Int,
        bot1StrengthDamagePerRound: [Int: Int],
        bot2StrengthDamagePerRound: [Int: Int]
    ) {
        self.bot1CritAttempts = bot1CritAttempts
        self.bot1CritSuccesses = bot1CritSuccesses
        self.bot1CritMultipliers = bot1CritMultipliers
        self.bot2CritAttempts = bot2CritAttempts
        self.bot2CritSuccesses = bot2CritSuccesses
        self.bot2CritMultipliers = bot2CritMultipliers
        self.bot1CritBlockBreaks = bot1CritBlockBreaks
        self.bot2CritBlockBreaks = bot2CritBlockBreaks
        self.bot1CritsDodged = bot1CritsDodged
        self.bot2CritsDodged = bot2CritsDodged
        self.bot1DodgeAttempts = bot1DodgeAttempts
        self.bot1DodgeSuccesses = bot1DodgeSuccesses
        self.bot2DodgeAttempts = bot2DodgeAttempts
        self.bot2DodgeSuccesses = bot2DodgeSuccesses
        self.bot1TotalDamage = bot1TotalDamage
        self.bot2TotalDamage = bot2TotalDamage
        self.bot1DamagePerRound = bot1DamagePerRound
        self.bot2DamagePerRound = bot2DamagePerRound
        self.bot1TotalStrengthDamage = bot1TotalStrengthDamage
        self.bot2TotalStrengthDamage = bot2TotalStrengthDamage
        self.bot1StrengthDamagePerRound = bot1StrengthDamagePerRound
        self.bot2StrengthDamagePerRound = bot2StrengthDamagePerRound
    }

    // MARK: - Computed Properties

    /// Crit success rate for bot1 (0.0 - 1.0)
    public var bot1CritRate: Double {
        guard bot1CritAttempts > 0 else { return 0.0 }
        return Double(bot1CritSuccesses) / Double(bot1CritAttempts)
    }

    /// Crit success rate for bot2 (0.0 - 1.0)
    public var bot2CritRate: Double {
        guard bot2CritAttempts > 0 else { return 0.0 }
        return Double(bot2CritSuccesses) / Double(bot2CritAttempts)
    }

    /// Rate of crits that broke blocks for bot1 (block breaks / total crits)
    public var bot1CritBlockBreakRate: Double {
        guard bot1CritSuccesses > 0 else { return 0.0 }
        return Double(bot1CritBlockBreaks) / Double(bot1CritSuccesses)
    }

    /// Rate of crits that broke blocks for bot2
    public var bot2CritBlockBreakRate: Double {
        guard bot2CritSuccesses > 0 else { return 0.0 }
        return Double(bot2CritBlockBreaks) / Double(bot2CritSuccesses)
    }

    /// Rate of crits that were dodged from bot1 (dodged crits / total crits)
    public var bot1CritsDodgedRate: Double {
        guard bot1CritSuccesses > 0 else { return 0.0 }
        return Double(bot1CritsDodged) / Double(bot1CritSuccesses)
    }

    /// Rate of crits that were dodged from bot2
    public var bot2CritsDodgedRate: Double {
        guard bot2CritSuccesses > 0 else { return 0.0 }
        return Double(bot2CritsDodged) / Double(bot2CritSuccesses)
    }

    /// Dodge success rate for bot1 (0.0 - 1.0)
    public var bot1DodgeRate: Double {
        guard bot1DodgeAttempts > 0 else { return 0.0 }
        return Double(bot1DodgeSuccesses) / Double(bot1DodgeAttempts)
    }

    /// Dodge success rate for bot2 (0.0 - 1.0)
    public var bot2DodgeRate: Double {
        guard bot2DodgeAttempts > 0 else { return 0.0 }
        return Double(bot2DodgeSuccesses) / Double(bot2DodgeAttempts)
    }

    /// Average damage per round for bot1
    public var bot1AverageDamagePerRound: Double {
        guard !bot1DamagePerRound.isEmpty else { return 0.0 }
        return Double(bot1TotalDamage) / Double(bot1DamagePerRound.count)
    }

    /// Average damage per round for bot2
    public var bot2AverageDamagePerRound: Double {
        guard !bot2DamagePerRound.isEmpty else { return 0.0 }
        return Double(bot2TotalDamage) / Double(bot2DamagePerRound.count)
    }

    /// Average strength damage per round for bot1
    public var bot1AverageStrengthDamagePerRound: Double {
        guard !bot1StrengthDamagePerRound.isEmpty else { return 0.0 }
        return Double(bot1TotalStrengthDamage) / Double(bot1StrengthDamagePerRound.count)
    }

    /// Average strength damage per round for bot2
    public var bot2AverageStrengthDamagePerRound: Double {
        guard !bot2StrengthDamagePerRound.isEmpty else { return 0.0 }
        return Double(bot2TotalStrengthDamage) / Double(bot2StrengthDamagePerRound.count)
    }
}

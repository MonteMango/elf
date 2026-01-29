//
//  BattleResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Complete result of an auto-battle between two bots
///
/// Contains:
/// - Winner and final state
/// - Round-by-round history
/// - Detailed statistics (crit%, dodge%, damage)
/// - Original battle configuration
public struct BattleResult: Sendable, Identifiable {

    public let id: UUID

    // MARK: - Battle Configuration

    /// The original battle that was executed
    public let battle: Battle

    // MARK: - Result

    /// Who won the battle (bot1, bot2, or draw if both HP <= 0)
    /// Note: In Battle model, playerHero = bot1, botHero = bot2
    public enum Winner: Sendable, Equatable {
        case bot1
        case bot2
        case draw
    }

    public let winner: Winner

    /// Total number of rounds fought
    public let totalRounds: Int

    /// Bot1's final HP
    public let bot1FinalHP: Int

    /// Bot2's final HP
    public let bot2FinalHP: Int

    // MARK: - History & Statistics

    /// Round-by-round history
    public let roundHistory: [AutoBattleRoundResult]

    /// Aggregated statistics across all rounds
    public let statistics: BattleStatistics

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        battle: Battle,
        winner: Winner,
        totalRounds: Int,
        bot1FinalHP: Int,
        bot2FinalHP: Int,
        roundHistory: [AutoBattleRoundResult],
        statistics: BattleStatistics
    ) {
        self.id = id
        self.battle = battle
        self.winner = winner
        self.totalRounds = totalRounds
        self.bot1FinalHP = bot1FinalHP
        self.bot2FinalHP = bot2FinalHP
        self.roundHistory = roundHistory
        self.statistics = statistics
    }
}

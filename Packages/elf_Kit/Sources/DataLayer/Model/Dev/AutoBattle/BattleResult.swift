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

    /// Which side won the battle. Mirrors `Battle.leftTeam` / `rightTeam`.
    /// Used only by dev-simulation flows (`AutoBattleViewModel`,
    /// `ElfBattleSimulationService`); production manual-battle results use
    /// the player-perspective `BattleOutcome` directly.
    public enum Winner: Sendable, Equatable {
        case left
        case right
        case draw

        /// Maps from the team-perspective `BattleOutcome`. Used by AutoBattle
        /// and ElfBattleSimulationService to derive the 1v1 winner from
        /// `detectBattleOutcome`'s output.
        public init(from outcome: BattleOutcome) {
            switch outcome {
            case .victory: self = .left
            case .defeat:  self = .right
            case .draw:    self = .draw
            }
        }
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

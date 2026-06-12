//
//  WorldTurnOutcome.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Foundation

/// The result of an entire world turn — every AI elf's `BotTurnResult`. Built
/// off-main by `WorldTurnRunner`, then applied to the game in a single
/// main-actor pass by `GameSession.applyWorldTurn`.
public struct WorldTurnOutcome: Sendable, Equatable {
    public let results: [BotTurnResult]

    public init(results: [BotTurnResult]) {
        self.results = results
    }

    // MARK: - Analytics conveniences

    /// Number of bots that took a turn.
    public var botCount: Int { results.count }

    /// Total battles fought across all bots.
    public var totalBattles: Int {
        results.reduce(0) { $0 + $1.battles.count }
    }

    /// Total battles won across all bots.
    public var totalWins: Int {
        results.reduce(0) { $0 + $1.battles.filter(\.won).count }
    }

    /// Total experience earned across all bots.
    public var totalExperience: Int {
        results.reduce(0) { $0 + $1.experienceGained }
    }
}

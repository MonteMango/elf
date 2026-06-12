//
//  DefaultWorldTurnRunner.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Dependencies
import Foundation

/// Default orchestrator: fans the bots out across a `TaskGroup` so they
/// simulate concurrently on the cooperative pool, then reassembles the results
/// in input order.
///
/// Each bot gets an independent per-bot seed derived from `turnSeed` and its
/// index, so battles never contend on a shared RNG and the whole turn is
/// reproducible from a single seed.
public final class DefaultWorldTurnRunner: WorldTurnRunner {

    // MARK: - Dependencies (snapshotted at init)

    private let decisionMaker: any BotDecisionMaker
    private let simulator: any BotTurnSimulator

    // MARK: - Initialization

    public init() {
        @Dependency(\.botDecisionMaker) var decisionMaker
        @Dependency(\.botTurnSimulator) var simulator
        self.decisionMaker = decisionMaker
        self.simulator = simulator
    }

    // MARK: - WorldTurnRunner

    public func run(bots: [BotTurnContext], turnSeed: UInt64) async -> WorldTurnOutcome {
        guard !bots.isEmpty else { return WorldTurnOutcome(results: []) }

        // Capture immutable deps locally so the task closures stay `Sendable`
        // without retaining `self`.
        let decisionMaker = self.decisionMaker
        let simulator = self.simulator

        let indexed = await withTaskGroup(of: (Int, BotTurnResult).self) { group in
            for (index, bot) in bots.enumerated() {
                let seed = turnSeed &+ UInt64(index) &* 0x9E3779B97F4A7C15
                group.addTask {
                    let plan = decisionMaker.planTurn(for: bot.elf, at: bot.slot)
                    let result = await simulator.simulate(plan, elf: bot.elf, seed: seed)
                    return (index, result)
                }
            }

            var collected: [(Int, BotTurnResult)] = []
            collected.reserveCapacity(bots.count)
            for await pair in group { collected.append(pair) }
            return collected
        }

        let ordered = indexed.sorted { $0.0 < $1.0 }.map(\.1)
        return WorldTurnOutcome(results: ordered)
    }
}

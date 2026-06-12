//
//  WorldTurnRunnerTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests the orchestration contract of `DefaultWorldTurnRunner`: input order is
/// preserved, the run is reproducible from `turnSeed`, and each bot receives an
/// independent per-bot seed. A stub simulator echoes its seed into the result
/// so seed derivation can be observed without invoking the battle engine.
@MainActor
final class WorldTurnRunnerTests: XCTestCase {

    // MARK: - Stub

    /// Echoes the per-bot seed into `experienceGained` and reflects the plan's
    /// AP cost, so tests can assert on seed derivation and planning.
    private struct SeedEchoSimulator: BotTurnSimulator {
        func simulate(_ plan: BotTurnPlan, elf: ElfInfo, seed: UInt64) async -> BotTurnResult {
            BotTurnResult(
                slot: plan.slot,
                experienceGained: Int(seed % 1_000_000),
                materials: [],
                weapons: [],
                armor: [],
                actionPointsSpent: plan.totalCost,
                battles: []
            )
        }
    }

    // MARK: - Helpers

    private func makeBots(_ count: Int) -> [BotTurnContext] {
        (0..<count).map { index in
            let slot = RosterSlot(
                houseIndex: index / House.membersCount,
                memberIndex: index % House.membersCount,
                id: ElfID()
            )
            return BotTurnContext(slot: slot, elf: TestFixtures.elf())
        }
    }

    private func run(_ bots: [BotTurnContext], seed: UInt64) async -> WorldTurnOutcome {
        await withDependencies {
            $0.botDecisionMaker = DefaultBotDecisionMaker()
            $0.botTurnSimulator = SeedEchoSimulator()
        } operation: {
            await DefaultWorldTurnRunner().run(bots: bots, turnSeed: seed)
        }
    }

    // MARK: - Tests

    func testRun_preservesInputOrder() async {
        let bots = makeBots(5)

        let outcome = await run(bots, seed: 42)

        XCTAssertEqual(outcome.results.map(\.slot), bots.map(\.slot))
    }

    func testRun_isDeterministic_forSameSeed() async {
        let bots = makeBots(8)

        let first = await run(bots, seed: 123)
        let second = await run(bots, seed: 123)

        XCTAssertEqual(first, second)
    }

    func testRun_differentSeed_changesOutcome() async {
        let bots = makeBots(8)

        let first = await run(bots, seed: 1)
        let second = await run(bots, seed: 2)

        XCTAssertNotEqual(first, second)
    }

    func testRun_eachBotGetsDistinctSeed() async {
        let bots = makeBots(10)

        let outcome = await run(bots, seed: 999)

        let echoedSeeds = outcome.results.map(\.experienceGained)
        XCTAssertEqual(Set(echoedSeeds).count, echoedSeeds.count)
    }

    func testRun_planSpendsFullActionPoints() async {
        let outcome = await run(makeBots(1), seed: 5)

        // 100 AP / 20 per hunt = 5 hunts = 100 AP spent.
        XCTAssertEqual(outcome.results.first?.actionPointsSpent, 100)
    }

    func testRun_emptyBots_emptyOutcome() async {
        let outcome = await run([], seed: 7)

        XCTAssertTrue(outcome.results.isEmpty)
    }
}

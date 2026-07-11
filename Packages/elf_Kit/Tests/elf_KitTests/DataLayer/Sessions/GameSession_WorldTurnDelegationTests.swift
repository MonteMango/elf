//
//  GameSession_WorldTurnDelegationTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// AC-06 real-delegation check for T12: `GameSession.applyWorldTurn` must
/// reduce to a single delegating call into the injected `WorldTurnMutator` —
/// not reimplement the per-bot exp/drops/AP rule inline. Proven here with a
/// spy mutator whose canned return value is deliberately impossible for
/// `GameSession` to have produced on its own (sentinel exp / sentinel house
/// name): if the session's observable post-call state exactly mirrors the
/// spy's output, the facade must be *using* the injected value rather than
/// computing its own.
@MainActor
final class GameSession_WorldTurnDelegationTests: XCTestCase {

    // MARK: - Spy

    private final class SpyWorldTurnMutator: WorldTurnMutator, @unchecked Sendable {
        var applyWorldTurnCallCount = 0
        var receivedOutcome: WorldTurnOutcome?
        var receivedHouses: [House]?
        let sentinelHouses: [House]

        init(sentinelHouses: [House]) {
            self.sentinelHouses = sentinelHouses
        }

        func applyWorldTurn(_ outcome: WorldTurnOutcome, to houses: [House]) -> [House] {
            applyWorldTurnCallCount += 1
            receivedOutcome = outcome
            receivedHouses = houses
            return sentinelHouses
        }
    }

    // MARK: - Fixtures

    private func makeGame() -> Game {
        let player = TestFixtures.elf(name: "Player")
        let houses = (0..<Game.housesCount).map { houseIndex -> House in
            let members = (0..<House.membersCount).map { memberIndex -> ElfInfo in
                (houseIndex == 0 && memberIndex == 0) ? player : TestFixtures.elf()
            }
            return House(name: "H\(houseIndex)", logoImageName: "logo", members: members)
        }
        let calendar = [GameDay(dayNumber: 1, dayType: .normal)]
        return Game(
            houses: houses,
            gameState: GameState(currentDay: calendar[0], calendar: calendar),
            playerHouseIndex: 0,
            playerMemberIndex: 0
        )
    }

    private func makeSession() -> GameSession {
        GameSession(game: makeGame())
    }

    private func sentinelHouses(from game: Game) -> [House] {
        game.houses.enumerated().map { index, house in
            House(name: "SENTINEL-\(index)", logoImageName: house.logoImageName, members: house.members)
        }
    }

    // MARK: - applyWorldTurn

    func testApplyWorldTurn_DelegatesToInjectedMutator() {
        let game = makeGame()
        let sentinel = sentinelHouses(from: game)
        let spy = SpyWorldTurnMutator(sentinelHouses: sentinel)

        let session = withDependencies {
            $0.worldTurnMutator = spy
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
        } operation: {
            let session = GameSession(game: game)
            let outcome = WorldTurnOutcome(results: [])
            session.applyWorldTurn(outcome)
            return session
        }

        XCTAssertEqual(spy.applyWorldTurnCallCount, 1)
        // The facade wrote the mutator's reported houses into state — proof
        // it applied the *injected* value, not one it computed inline (a
        // real per-bot loop could never produce these sentinel house names).
        XCTAssertEqual(session.state.houses.map(\.name), sentinel.map(\.name))
    }

    func testApplyWorldTurn_PassesOutcomeAndCurrentHousesToMutator() {
        let game = makeGame()
        let spy = SpyWorldTurnMutator(sentinelHouses: sentinelHouses(from: game))
        let botId = game.houses[0].members[1].id
        let result = BotTurnResult(
            slot: RosterSlot(houseIndex: 0, memberIndex: 1, id: botId),
            experienceGained: 10,
            materials: [],
            weapons: [],
            armor: [],
            actionPointsSpent: 0,
            battles: []
        )
        let outcome = WorldTurnOutcome(results: [result])

        withDependencies {
            $0.worldTurnMutator = spy
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
        } operation: {
            let session = GameSession(game: game)
            session.applyWorldTurn(outcome)
        }

        XCTAssertEqual(spy.receivedOutcome, outcome)
        XCTAssertEqual(spy.receivedHouses?.map(\.name), game.houses.map(\.name))
    }
}

//
//  GameSession_WorldTurnTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests `GameSession.applyWorldTurn(_:)` (per-elf reward application) and the
/// all-elves AP reset in `advanceToNextDay()`.
@MainActor
final class GameSession_WorldTurnTests: XCTestCase {

    /// `applyWorldTurn` routes drops through the real `InventoryService`;
    /// `GameSession.init` also snapshots `craftService`.
    override func invokeTest() {
        withDependencies {
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
        } operation: {
            super.invokeTest()
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
        let calendar = [
            GameDay(dayNumber: 1, dayType: .normal),
            GameDay(dayNumber: 2, dayType: .normal)
        ]
        return Game(
            houses: houses,
            gameState: GameState(currentDay: calendar[0], calendar: calendar),
            playerHouseIndex: 0,
            playerMemberIndex: 0
        )
    }

    private func makeSession() -> (GameSession, GameStore) {
        let session = GameSession(game: makeGame())
        return (session, session.state)
    }

    private func botResult(
        houseIndex: Int,
        memberIndex: Int,
        id: ElfID,
        exp: Int = 0,
        materials: [MaterialReward] = [],
        apSpent: Int = 0
    ) -> BotTurnResult {
        BotTurnResult(
            slot: RosterSlot(houseIndex: houseIndex, memberIndex: memberIndex, id: id),
            experienceGained: exp,
            materials: materials,
            weapons: [],
            armor: [],
            actionPointsSpent: apSpent,
            battles: []
        )
    }

    // MARK: - applyWorldTurn

    func testApplyWorldTurn_appliesExpDropsAndAP_toTargetedBot() {
        let (session, store) = makeSession()
        let botId = store.houses[0].members[1].id
        let materialId = MaterialID()
        let result = botResult(
            houseIndex: 0, memberIndex: 1, id: botId,
            exp: 50,
            materials: [MaterialReward(id: materialId, amount: 3)],
            apSpent: 40
        )

        session.applyWorldTurn(WorldTurnOutcome(results: [result]))

        let bot = store.houses[0].members[1]
        XCTAssertEqual(bot.currentExp, 50)
        XCTAssertEqual(bot.actionPoints.current, 60)
        XCTAssertEqual(bot.inventory.materials.first?.quantity, 3)
    }

    func testApplyWorldTurn_leavesPlayerUntouched() {
        let (session, store) = makeSession()
        let botId = store.houses[0].members[1].id
        let result = botResult(houseIndex: 0, memberIndex: 1, id: botId, exp: 99, apSpent: 100)

        session.applyWorldTurn(WorldTurnOutcome(results: [result]))

        XCTAssertEqual(store.player.currentExp, 0)
        XCTAssertEqual(store.player.actionPoints.current, 100)
    }

    func testApplyWorldTurn_idMismatch_skipsApplication() {
        let (session, store) = makeSession()
        // A slot whose id does not match the elf actually living there.
        let result = botResult(houseIndex: 0, memberIndex: 1, id: ElfID(), exp: 999, apSpent: 20)

        session.applyWorldTurn(WorldTurnOutcome(results: [result]))

        let bot = store.houses[0].members[1]
        XCTAssertEqual(bot.currentExp, 0)
        XCTAssertEqual(bot.actionPoints.current, 100)
    }

    // MARK: - advanceToNextDay

    func testAdvanceToNextDay_resetsActionPointsForAllElves() {
        let (session, store) = makeSession()
        session.spendActionPoints(40)                                   // player → 60
        session.spendActionPoints(80, forElfAt: 0, memberIndex: 1)      // bot → 20
        XCTAssertEqual(store.player.actionPoints.current, 60)
        XCTAssertEqual(store.houses[0].members[1].actionPoints.current, 20)

        session.advanceToNextDay()

        XCTAssertEqual(store.currentDay.dayNumber, 2)
        XCTAssertEqual(store.player.actionPoints.current, 100)
        XCTAssertEqual(store.houses[0].members[1].actionPoints.current, 100)
    }
}

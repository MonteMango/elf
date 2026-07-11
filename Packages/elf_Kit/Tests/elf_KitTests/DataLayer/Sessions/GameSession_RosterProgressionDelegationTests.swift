//
//  GameSession_RosterProgressionDelegationTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// AC-06 real-delegation check for T8: `GameSession.addExperience` / `.addDrops`
/// (Roster Progression MARK, any elf) and `.addDropsToPlayerInventory` (Player
/// Progression MARK, which routes into `.addDrops`) must reduce to a single
/// delegating call into the injected `RosterProgressionMutator` — not
/// reimplement the progression rule inline. Proven here with a spy mutator
/// whose canned return values are deliberately impossible for `GameSession` to
/// have produced on its own (sentinel exp / sentinel inventory shape): if the
/// session's observable post-call state exactly mirrors the spy's output, the
/// facade must be *using* the injected value rather than computing its own.
@MainActor
final class GameSession_RosterProgressionDelegationTests: XCTestCase {

    // MARK: - Spy

    private final class SpyRosterProgressionMutator: RosterProgressionMutator, @unchecked Sendable {
        var addExperienceCallCount = 0
        var receivedCurrentExp: [Int] = []
        let sentinelExp: Int

        var addDropsCallCount = 0
        let sentinelInventory: ElfInventory

        init(sentinelExp: Int, sentinelInventory: ElfInventory) {
            self.sentinelExp = sentinelExp
            self.sentinelInventory = sentinelInventory
        }

        func addExperience(_ amount: Int, to currentExp: Int) -> Int {
            addExperienceCallCount += 1
            receivedCurrentExp.append(currentExp)
            return sentinelExp
        }

        func addDrops(
            materials: [MaterialReward],
            weapons: [ElfWeaponItem],
            armor: [ElfDefenseItem],
            to inventory: ElfInventory
        ) -> ElfInventory {
            addDropsCallCount += 1
            return sentinelInventory
        }
    }

    // MARK: - Fixtures

    private func makeGame(playerCurrentExp: Int) -> Game {
        let player = TestFixtures.elf(currentExp: playerCurrentExp)
        let members = [player] + (0..<(House.membersCount - 1)).map { _ in TestFixtures.elf() }
        let houses: [House] = (0..<Game.housesCount).map { i in
            House(name: "H\(i)", logoImageName: "logo", members: members)
        }
        let calendar = [GameDay(dayNumber: 1, dayType: .normal)]
        let gameState = GameState(currentDay: calendar[0], calendar: calendar)
        return Game(houses: houses, gameState: gameState, playerHouseIndex: 0, playerMemberIndex: 0)
    }

    private func makeSession(playerCurrentExp: Int = 0) -> GameSession {
        GameSession(game: makeGame(playerCurrentExp: playerCurrentExp))
    }

    // MARK: - addExperience

    func testAddExperience_DelegatesToInjectedMutator() {
        let sentinelExp = 987_654
        let spy = SpyRosterProgressionMutator(sentinelExp: sentinelExp, sentinelInventory: ElfInventory())

        let session = withDependencies {
            $0.rosterProgressionMutator = spy
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
        } operation: {
            let session = makeSession()
            session.addExperience(30, toElfAt: 0, memberIndex: 1)
            return session
        }

        XCTAssertEqual(spy.addExperienceCallCount, 1)
        // The facade wrote the mutator's reported exp into state — proof it
        // applied the *injected* value, not one it computed inline (a real
        // `+=` could never produce this sentinel).
        XCTAssertEqual(session.state.houses[0].members[1].currentExp, sentinelExp)
    }

    func testAddExperience_PassesCurrentExpToMutator() {
        let spy = SpyRosterProgressionMutator(sentinelExp: 0, sentinelInventory: ElfInventory())

        _ = withDependencies {
            $0.rosterProgressionMutator = spy
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
        } operation: {
            let session = makeSession()
            session.addExperience(30, toElfAt: 0, memberIndex: 1)
            return session
        }

        XCTAssertEqual(spy.receivedCurrentExp, [0])
    }

    // MARK: - addDrops (any elf)

    func testAddDrops_DelegatesToInjectedMutator() {
        var sentinel = ElfInventory()
        sentinel.materials = [InventoryMaterial(ref: .monster(MaterialID()), quantity: 999)]
        let spy = SpyRosterProgressionMutator(sentinelExp: 0, sentinelInventory: sentinel)

        let session = withDependencies {
            $0.rosterProgressionMutator = spy
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
        } operation: {
            let session = makeSession()
            session.addDrops(materials: [], weapons: [], armor: [], toElfAt: 0, memberIndex: 1)
            return session
        }

        XCTAssertEqual(spy.addDropsCallCount, 1)
        // The facade wrote the mutator's reported inventory into state —
        // proof it applied the *injected* value, not one it computed inline.
        XCTAssertEqual(session.state.houses[0].members[1].inventory, sentinel)
    }

    // MARK: - addDropsToPlayerInventory (Player Progression MARK routes into addDrops)

    func testAddDropsToPlayerInventory_HuntRewardsOverload_DelegatesViaAddDrops() {
        var sentinel = ElfInventory()
        sentinel.materials = [InventoryMaterial(ref: .monster(MaterialID()), quantity: 42)]
        let spy = SpyRosterProgressionMutator(sentinelExp: 0, sentinelInventory: sentinel)

        let session = withDependencies {
            $0.rosterProgressionMutator = spy
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
        } operation: {
            let session = makeSession()
            let rewards = HuntRewards(experience: 0, materials: [])
            session.addDropsToPlayerInventory(rewards: rewards)
            return session
        }

        XCTAssertEqual(spy.addDropsCallCount, 1)
        XCTAssertEqual(session.state.player.inventory, sentinel)
    }
}

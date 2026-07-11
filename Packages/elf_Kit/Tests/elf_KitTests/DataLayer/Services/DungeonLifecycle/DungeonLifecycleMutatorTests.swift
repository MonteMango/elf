//
//  DungeonLifecycleMutatorTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests the `DungeonLifecycleMutator` extracted from `GameSession`'s Dungeon
/// Session Lifecycle rule family (T11): starting a run, flushing accrued
/// rewards into the player, banking on death, and finishing/discarding a run.
/// Exercised directly against the injected type (via
/// `@Dependency(\.dungeonLifecycleMutator)`), independent of `GameSession` —
/// `GameSession_DungeonLifecycleDelegationTests` covers the delegation
/// through the facade and must keep passing unchanged.
@MainActor
final class DungeonLifecycleMutatorTests: XCTestCase {

    // MARK: - Fixtures

    private let dungeonId = DungeonID(rawValue: UUID())
    private let roomAId = DungeonRoomID(rawValue: UUID())

    private struct FakeDungeonRepository: DungeonRepository {
        let dungeon: Dungeon
        func getAll() -> [Dungeon] { [dungeon] }
        func getById(id: DungeonID) -> Dungeon? { id == dungeon.id ? dungeon : nil }
        func randomDungeon() -> Dungeon? { dungeon }
    }

    private func makeDungeon() -> Dungeon {
        let roomA = DungeonRoom(id: roomAId, title: "Entry", kind: .combat([]), nextRoomIds: [])
        return Dungeon(
            id: dungeonId, title: "Test Dungeon", description: "",
            type: .onePath, world: .upper, backgroundImageName: "bg",
            entryRoomIds: [roomAId], rooms: [roomA]
        )
    }

    private func makeGameStore() -> GameStore {
        let player = TestFixtures.elf(currentExp: 0)
        let ally = TestFixtures.elf()
        let others = (0..<(House.membersCount - 2)).map { _ in TestFixtures.elf() }
        let members = [player, ally] + others
        let houses: [House] = (0..<Game.housesCount).map { i in
            House(name: "H\(i)", logoImageName: "logo", members: members)
        }
        let calendar = [GameDay(dayNumber: 1, dayType: .normal)]
        let game = Game(
            houses: houses,
            gameState: GameState(currentDay: calendar[0], calendar: calendar),
            playerHouseIndex: 0,
            playerMemberIndex: 0
        )
        return GameStore(from: game)
    }

    private func makeMutator() -> any DungeonLifecycleMutator {
        @Dependency(\.dungeonLifecycleMutator) var mutator
        return mutator
    }

    /// Builds a dungeon session with a non-empty pending-rewards ledger by
    /// restoring a save snapshot (materials-only, so no `ItemsRepository`
    /// dependency is pulled in).
    private func makeSessionWithPendingRewards(
        gameStore: GameStore,
        experience: Int,
        materialId: MaterialID
    ) -> DungeonSession {
        withDependencies {
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
        } operation: {
            let session = DungeonSession(gameStore: gameStore, dungeonId: dungeonId, allyIds: [])
            session.restore(from: DungeonRunSaveData(
                dungeonId: dungeonId,
                allyIds: [],
                elfLocations: [:],
                roomVitals: [:],
                clearedRoomIds: [],
                pendingRewards: DungeonRunRewardsSaveData(
                    experience: experience,
                    materials: [MaterialReward(id: materialId, amount: 3)],
                    weapons: [],
                    armor: []
                )
            ))
            return session
        }
    }

    // MARK: - startDungeonSession

    func testStartDungeonSession_CreatesSessionWithGivenDungeonAndAllies() {
        let store = makeGameStore()
        let allyId = ElfID()
        let mutator = withDependencies {
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
        } operation: {
            makeMutator()
        }

        let session = withDependencies {
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
        } operation: {
            mutator.startDungeonSession(gameStore: store, dungeonId: dungeonId, allyIds: [allyId])
        }

        XCTAssertEqual(session.dungeonId, dungeonId)
        XCTAssertEqual(session.allyIds, [allyId])
    }

    // MARK: - flushRewards

    func testFlushRewards_AddsExperienceAndMaterialsToPlayer_AndClearsLedger() {
        let store = withDependencies {
            $0.inventoryService = ElfInventoryService()
        } operation: {
            makeGameStore()
        }
        let materialId = MaterialID(rawValue: UUID())
        let dungeonSession = makeSessionWithPendingRewards(
            gameStore: store, experience: 250, materialId: materialId
        )

        withDependencies {
            $0.inventoryService = ElfInventoryService()
        } operation: {
            makeMutator().flushRewards(from: dungeonSession, into: store)
        }

        XCTAssertEqual(store.player.currentExp, 250)
        XCTAssertTrue(store.player.inventory.materials.contains { $0.ref == .monster(materialId) })
        XCTAssertEqual(dungeonSession.pendingRewards, .empty)
    }

    // MARK: - bankDungeonRewardsOnDeath

    func testBankDungeonRewardsOnDeath_WithSession_FlushesRewards() {
        let store = withDependencies {
            $0.inventoryService = ElfInventoryService()
        } operation: {
            makeGameStore()
        }
        let materialId = MaterialID(rawValue: UUID())
        let dungeonSession = makeSessionWithPendingRewards(
            gameStore: store, experience: 42, materialId: materialId
        )

        withDependencies {
            $0.inventoryService = ElfInventoryService()
        } operation: {
            makeMutator().bankDungeonRewardsOnDeath(dungeonSession: dungeonSession, into: store)
        }

        XCTAssertEqual(store.player.currentExp, 42)
        XCTAssertEqual(dungeonSession.pendingRewards, .empty)
    }

    func testBankDungeonRewardsOnDeath_NilSession_DoesNotMutatePlayer() {
        let store = makeGameStore()

        makeMutator().bankDungeonRewardsOnDeath(dungeonSession: nil, into: store)

        XCTAssertEqual(store.player.currentExp, 0)
    }

    // MARK: - finishDungeonRun

    func testFinishDungeonRun_FlushesRewardsAndReleasesSession() {
        let store = withDependencies {
            $0.inventoryService = ElfInventoryService()
        } operation: {
            makeGameStore()
        }
        let materialId = MaterialID(rawValue: UUID())
        let dungeonSession = makeSessionWithPendingRewards(
            gameStore: store, experience: 99, materialId: materialId
        )

        let released = withDependencies {
            $0.inventoryService = ElfInventoryService()
        } operation: {
            makeMutator().finishDungeonRun(dungeonSession: dungeonSession, into: store)
        }

        XCTAssertEqual(store.player.currentExp, 99)
        XCTAssertNil(released)
    }

    func testFinishDungeonRun_NilSession_ReturnsNilAndDoesNotMutatePlayer() {
        let store = makeGameStore()

        let released = makeMutator().finishDungeonRun(dungeonSession: nil, into: store)

        XCTAssertNil(released)
        XCTAssertEqual(store.player.currentExp, 0)
    }

    // MARK: - discardDungeonRun / releaseDungeonSession

    func testDiscardDungeonRun_ReturnsNil() {
        XCTAssertNil(makeMutator().discardDungeonRun())
    }

    func testReleaseDungeonSession_ReturnsNil() {
        XCTAssertNil(makeMutator().releaseDungeonSession())
    }
}

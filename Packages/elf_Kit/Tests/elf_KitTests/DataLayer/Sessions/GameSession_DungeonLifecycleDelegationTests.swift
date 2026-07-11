//
//  GameSession_DungeonLifecycleDelegationTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// AC-06 real-delegation check for T11: `GameSession.startDungeonSession`,
/// `bankDungeonRewardsOnDeath`, `finishDungeonRun`, and `discardDungeonRun`
/// must each reduce to a single delegating call into the injected
/// `DungeonLifecycleMutator` — not reimplement the dungeon-lifecycle rule
/// inline. Proven here with a spy mutator whose canned return values are
/// deliberately impossible for `GameSession` to have produced on its own
/// (sentinel session / sentinel call counts): if the session's observable
/// post-call state exactly mirrors the spy's output, the facade must be
/// *using* the injected value rather than computing its own.
@MainActor
final class GameSession_DungeonLifecycleDelegationTests: XCTestCase {

    // MARK: - Spy

    private final class SpyDungeonLifecycleMutator: DungeonLifecycleMutator, @unchecked Sendable {
        var startDungeonSessionCallCount = 0
        var bankDungeonRewardsOnDeathCallCount = 0
        var flushRewardsCallCount = 0
        var finishDungeonRunCallCount = 0
        var discardDungeonRunCallCount = 0
        var releaseDungeonSessionCallCount = 0

        var receivedBankSession: DungeonSession?
        var receivedFinishSession: DungeonSession?

        let sentinelStartedSession: (GameStore, DungeonID, [ElfID]) -> DungeonSession

        init(sentinelStartedSession: @escaping (GameStore, DungeonID, [ElfID]) -> DungeonSession) {
            self.sentinelStartedSession = sentinelStartedSession
        }

        func startDungeonSession(gameStore: GameStore, dungeonId: DungeonID, allyIds: [ElfID]) -> DungeonSession {
            startDungeonSessionCallCount += 1
            return sentinelStartedSession(gameStore, dungeonId, allyIds)
        }

        func releaseDungeonSession() -> DungeonSession? {
            releaseDungeonSessionCallCount += 1
            return nil
        }

        func flushRewards(from dungeonSession: DungeonSession, into gameStore: GameStore) {
            flushRewardsCallCount += 1
        }

        func bankDungeonRewardsOnDeath(dungeonSession: DungeonSession?, into gameStore: GameStore) {
            bankDungeonRewardsOnDeathCallCount += 1
            receivedBankSession = dungeonSession
        }

        func finishDungeonRun(dungeonSession: DungeonSession?, into gameStore: GameStore) -> DungeonSession? {
            finishDungeonRunCallCount += 1
            receivedFinishSession = dungeonSession
            return nil
        }

        func discardDungeonRun() -> DungeonSession? {
            discardDungeonRunCallCount += 1
            return nil
        }
    }

    // MARK: - Fakes

    private struct NoOpStorage: GameSaveStorage {
        func save(_ game: Game, dungeonRun: DungeonRunSaveData?, slotId: String, playTime: TimeInterval) async throws {}
        func load(slotId: String) async throws -> LoadedSave { fatalError("unused") }
        func hasAnySave() -> Bool { false }
        func getPlayTime(slotId: String) async -> TimeInterval { 0 }
    }

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

    // MARK: - Fixtures

    private func makeGame() -> Game {
        let player = TestFixtures.elf()
        let members = [player] + (0..<(House.membersCount - 1)).map { _ in TestFixtures.elf() }
        let houses: [House] = (0..<Game.housesCount).map { i in
            House(name: "H\(i)", logoImageName: "logo", members: members)
        }
        let calendar = [GameDay(dayNumber: 1, dayType: .normal)]
        let gameState = GameState(currentDay: calendar[0], calendar: calendar)
        return Game(houses: houses, gameState: gameState, playerHouseIndex: 0, playerMemberIndex: 0)
    }

    private func makeSession(spy: SpyDungeonLifecycleMutator) -> GameSession {
        withDependencies {
            $0.gameRepository = NoOpStorage()
            $0.dungeonLifecycleMutator = spy
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
        } operation: {
            GameSession(game: makeGame())
        }
    }

    // MARK: - startDungeonSession delegates

    func testStartDungeonSession_DelegatesToInjectedMutatorAndStoresReturnedSession() {
        var sentinelSession: DungeonSession?
        let spy = SpyDungeonLifecycleMutator { gameStore, dungeonId, allyIds in
            let session = DungeonSession(gameStore: gameStore, dungeonId: dungeonId, allyIds: allyIds)
            sentinelSession = session
            return session
        }
        let session = makeSession(spy: spy)
        let allyId = ElfID()

        let returned = withDependencies {
            $0.dungeonLifecycleMutator = spy
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
        } operation: {
            session.startDungeonSession(dungeonId: dungeonId, allyIds: [allyId])
        }

        XCTAssertEqual(spy.startDungeonSessionCallCount, 1)
        XCTAssertTrue(returned === sentinelSession)
        XCTAssertTrue(session.dungeonSession === sentinelSession)
    }

    // MARK: - bankDungeonRewardsOnDeath delegates

    func testBankDungeonRewardsOnDeath_DelegatesToInjectedMutator() {
        let spy = SpyDungeonLifecycleMutator { gameStore, dungeonId, allyIds in
            DungeonSession(gameStore: gameStore, dungeonId: dungeonId, allyIds: allyIds)
        }
        let session = makeSession(spy: spy)
        withDependencies {
            $0.dungeonLifecycleMutator = spy
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
        } operation: {
            session.startDungeonSession(dungeonId: dungeonId, allyIds: [])
        }

        withDependencies {
            $0.dungeonLifecycleMutator = spy
        } operation: {
            session.bankDungeonRewardsOnDeath()
        }

        XCTAssertEqual(spy.bankDungeonRewardsOnDeathCallCount, 1)
        XCTAssertTrue(spy.receivedBankSession === session.dungeonSession)
    }

    // MARK: - finishDungeonRun delegates

    func testFinishDungeonRun_DelegatesToInjectedMutatorAndAppliesReturnedSession() {
        let spy = SpyDungeonLifecycleMutator { gameStore, dungeonId, allyIds in
            DungeonSession(gameStore: gameStore, dungeonId: dungeonId, allyIds: allyIds)
        }
        let session = makeSession(spy: spy)
        withDependencies {
            $0.dungeonLifecycleMutator = spy
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
        } operation: {
            session.startDungeonSession(dungeonId: dungeonId, allyIds: [])
        }
        XCTAssertNotNil(session.dungeonSession)

        withDependencies {
            $0.dungeonLifecycleMutator = spy
        } operation: {
            session.finishDungeonRun()
        }

        XCTAssertEqual(spy.finishDungeonRunCallCount, 1)
        // The spy's sentinel return value is nil — proof the facade wrote back
        // the mutator's result rather than releasing the session itself.
        XCTAssertNil(session.dungeonSession)
    }

    // MARK: - discardDungeonRun delegates

    func testDiscardDungeonRun_DelegatesToInjectedMutator() {
        let spy = SpyDungeonLifecycleMutator { gameStore, dungeonId, allyIds in
            DungeonSession(gameStore: gameStore, dungeonId: dungeonId, allyIds: allyIds)
        }
        let session = makeSession(spy: spy)
        withDependencies {
            $0.dungeonLifecycleMutator = spy
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
        } operation: {
            session.startDungeonSession(dungeonId: dungeonId, allyIds: [])
        }

        withDependencies {
            $0.dungeonLifecycleMutator = spy
        } operation: {
            session.discardDungeonRun()
        }

        XCTAssertEqual(spy.discardDungeonRunCallCount, 1)
        XCTAssertNil(session.dungeonSession)
    }
}

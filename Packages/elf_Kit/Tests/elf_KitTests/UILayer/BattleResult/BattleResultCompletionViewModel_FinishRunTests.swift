//
//  BattleResultCompletionViewModel_FinishRunTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// T4 / AC-03, AC-04, AC-07: `BattleResultCompletionViewModel.finishRun()` — the
/// hero-death continuation path's session-aware companion VM — must delegate to
/// `gameSession.completeDungeonRun()` (proven via the same spy mutator/storage as
/// `GameSession_DungeonRunCompletionTests`): with an active run it flushes rewards
/// and saves exactly once (AC-07: driven directly against the VM, no SwiftUI View
/// created or rendered); with no active run it is a strict no-op (AC-03/AC-04),
/// matching the single-owner completion path already proven at the `GameSession`
/// level.
@MainActor
final class BattleResultCompletionViewModel_FinishRunTests: XCTestCase {

    // MARK: - Spy mutator

    private final class SpyDungeonLifecycleMutator: DungeonLifecycleMutator, @unchecked Sendable {
        var finishDungeonRunCallCount = 0
        var receivedFinishSession: DungeonSession?

        let sentinelStartedSession: (GameStore, DungeonID, [ElfID]) -> DungeonSession

        init(sentinelStartedSession: @escaping (GameStore, DungeonID, [ElfID]) -> DungeonSession) {
            self.sentinelStartedSession = sentinelStartedSession
        }

        func startDungeonSession(gameStore: GameStore, dungeonId: DungeonID, allyIds: [ElfID]) -> DungeonSession {
            sentinelStartedSession(gameStore, dungeonId, allyIds)
        }

        func releaseDungeonSession() -> DungeonSession? { nil }

        func flushRewards(from dungeonSession: DungeonSession, into gameStore: GameStore) {}

        func bankDungeonRewardsOnDeath(dungeonSession: DungeonSession?, into gameStore: GameStore) {}

        func finishDungeonRun(dungeonSession: DungeonSession?, into gameStore: GameStore) -> DungeonSession? {
            finishDungeonRunCallCount += 1
            receivedFinishSession = dungeonSession
            return nil
        }

        func discardDungeonRun() -> DungeonSession? { nil }
    }

    // MARK: - Spy storage

    /// Counts `save(...)` calls so the no-op branch can assert zero saves were
    /// triggered, and the active-run branch can assert exactly one.
    private final class SpySaveStorage: GameSaveStorage, @unchecked Sendable {
        var saveCallCount = 0

        func save(_ game: Game, dungeonRun: DungeonRunSaveData?, slotId: String, playTime: TimeInterval) async throws {
            saveCallCount += 1
        }
        func load(slotId: String) async throws -> LoadedSave { fatalError("unused") }
        func hasAnySave() -> Bool { false }
        func getPlayTime(slotId: String) async -> TimeInterval { 0 }
    }

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

    private func makeSession(spy: SpyDungeonLifecycleMutator, storage: SpySaveStorage) -> GameSession {
        withDependencies {
            $0.gameRepository = storage
            $0.dungeonLifecycleMutator = spy
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
        } operation: {
            GameSession(game: makeGame())
        }
    }

    // MARK: - Active run: finishRun() delegates to completeDungeonRun()

    func testFinishRun_WithActiveRun_DelegatesToGameSessionCompleteDungeonRun() async {
        let spy = SpyDungeonLifecycleMutator { gameStore, dungeonId, allyIds in
            DungeonSession(gameStore: gameStore, dungeonId: dungeonId, allyIds: allyIds)
        }
        let storage = SpySaveStorage()
        let session = makeSession(spy: spy, storage: storage)
        withDependencies {
            $0.dungeonLifecycleMutator = spy
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
        } operation: {
            session.startDungeonSession(dungeonId: dungeonId, allyIds: [])
        }
        XCTAssertNotNil(session.dungeonSession)

        // AC-07: the completion unit is invoked directly against the companion
        // VM produced by the session factory — no SwiftUI View is created.
        let viewModel = session.makeBattleResultCompletionViewModel()

        withDependencies {
            $0.dungeonLifecycleMutator = spy
        } operation: {
            viewModel.finishRun()
        }
        await session.awaitInFlightSave()

        XCTAssertEqual(spy.finishDungeonRunCallCount, 1, "finishRun() must delegate to gameSession.completeDungeonRun()")
        XCTAssertNil(session.dungeonSession)
        XCTAssertEqual(storage.saveCallCount, 1)
    }

    // MARK: - No active run: finishRun() is a strict no-op (AC-03/AC-04)

    func testFinishRun_WithNoActiveRun_DoesNotFlushRewardsOrSave() {
        let spy = SpyDungeonLifecycleMutator { gameStore, dungeonId, allyIds in
            DungeonSession(gameStore: gameStore, dungeonId: dungeonId, allyIds: allyIds)
        }
        let storage = SpySaveStorage()
        let session = makeSession(spy: spy, storage: storage)
        XCTAssertNil(session.dungeonSession)

        let viewModel = session.makeBattleResultCompletionViewModel()

        withDependencies {
            $0.dungeonLifecycleMutator = spy
        } operation: {
            viewModel.finishRun()
        }

        XCTAssertEqual(spy.finishDungeonRunCallCount, 0)
        XCTAssertEqual(storage.saveCallCount, 0)
    }
}

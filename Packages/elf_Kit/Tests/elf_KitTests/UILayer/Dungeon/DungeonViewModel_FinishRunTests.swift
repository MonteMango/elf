//
//  DungeonViewModel_FinishRunTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// T3 / AC-03, AC-04, AC-07: `DungeonViewModel.finishRun()` must delegate to
/// `gameSession.completeDungeonRun()` with no duplicated finish+save logic
/// inline. Proven with a spy `DungeonLifecycleMutator` + spy `GameSaveStorage`
/// on a real `GameSession`: an active run's finish/save both happen exactly
/// once through the shared `completeDungeonRun()` path (AC-04's "no active
/// run is unreachable" pairs with AC-03's idempotent no-op, already proven
/// directly against `GameSession` in `GameSession_DungeonRunCompletionTests`).
/// Exercised directly against the VM (AC-07) — no SwiftUI View involved.
@MainActor
final class DungeonViewModel_FinishRunTests: XCTestCase {

    // MARK: - Spy mutator

    private final class SpyDungeonLifecycleMutator: DungeonLifecycleMutator, @unchecked Sendable {
        var finishDungeonRunCallCount = 0

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
            return nil
        }

        func discardDungeonRun() -> DungeonSession? { nil }
    }

    // MARK: - Spy storage

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

    // MARK: - AC-03/AC-04/AC-07: finishRun() delegates to completeDungeonRun()

    func testFinishRun_WithActiveRun_DelegatesToGameSessionCompleteDungeonRun() async {
        let spy = SpyDungeonLifecycleMutator { gameStore, dungeonId, allyIds in
            DungeonSession(gameStore: gameStore, dungeonId: dungeonId, allyIds: allyIds)
        }
        let storage = SpySaveStorage()
        let session = makeSession(spy: spy, storage: storage)

        let dungeonSession = withDependencies {
            $0.dungeonLifecycleMutator = spy
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
        } operation: {
            session.startDungeonSession(dungeonId: dungeonId, allyIds: [])
        }
        XCTAssertNotNil(session.dungeonSession)

        let viewModel = DungeonViewModel(session: dungeonSession, gameSession: session)

        withDependencies {
            $0.dungeonLifecycleMutator = spy
        } operation: {
            viewModel.finishRun()
        }
        await session.awaitInFlightSave()

        XCTAssertEqual(
            spy.finishDungeonRunCallCount, 1,
            "finishRun() must delegate to gameSession.completeDungeonRun(), which flushes rewards via the mutator exactly once"
        )
        XCTAssertNil(session.dungeonSession, "finishRun() must release the completed run on gameSession")
        XCTAssertEqual(
            storage.saveCallCount, 1,
            "finishRun() must not duplicate finish+save logic — the save must come from gameSession.completeDungeonRun(), not from finishRun() itself"
        )
    }
}

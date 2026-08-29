//
//  GameDayViewModel_ExitGameTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// T8 / AC-05, AC-06, AC-06b, AC-07: `GameDayViewModel.exitGame()` must (1) await
/// any prior in-flight background save before issuing its own exit save, (2) catch
/// and log a failed save via `DebugGameLogger` instead of letting it propagate, and
/// (3) always complete (single, unconditional return) so the caller can proceed to
/// `AppCoordinator.endGame()` regardless of save outcome. Proven directly against
/// `GameDayViewModel` + a real `GameSession` wired with spy/gated fakes — no
/// SwiftUI View involved (AC-07).
@MainActor
final class GameDayViewModel_ExitGameTests: XCTestCase {

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

    private func makeSessionAndViewModel(
        storage: any GameSaveStorage,
        logger: any DebugGameLogger
    ) -> (GameSession, GameDayViewModel) {
        withDependencies {
            $0.gameRepository = storage
            $0.debugGameLogger = logger
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
            $0.itemsRepository = ElfItemsRepository(heroItems: .empty)
            $0.equippedSlotResolver = DefaultHeroEquippedSlotResolver()
            $0.progressionService = ElfProgressionService()
            $0.equipmentQueryService = ElfEquipmentQueryService()
            $0.dungeonRepository = FakeDungeonRepository()
        } operation: {
            let session = GameSession(game: makeGame())
            let viewModel = GameDayViewModel(session: session)
            return (session, viewModel)
        }
    }

    /// Polls `condition` until it becomes true or `timeout` elapses. Used only
    /// to give a buggy implementation ample real time to (wrongly) race ahead
    /// of a still-gated save — a correct implementation blocks deterministically
    /// on the gate and never depends on this timing.
    private func waitUntil(timeout: TimeInterval = 1.0, _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    // MARK: - Fakes

    /// `GameDayViewModel` resolves `dungeonRepository` eagerly at init even
    /// though `exitGame()` never touches it — an empty pool is sufficient.
    private struct FakeDungeonRepository: DungeonRepository {
        func getAll() -> [Dungeon] { [] }
        func getById(id: DungeonID) -> Dungeon? { nil }
        func randomDungeon() -> Dungeon? { nil }
    }

    /// A `GameSaveStorage` whose `save(...)` blocks on a manually-released gate.
    /// Lets a test observe exactly when a save call starts, keep it suspended,
    /// and control when it's allowed to finish — the only way to prove ordering
    /// between a prior in-flight save and a subsequent one without any timing
    /// guesswork.
    private final class GatedGameSaveStorage: GameSaveStorage, @unchecked Sendable {
        private(set) var saveCallCount = 0
        private(set) var events: [String] = []
        private var gateReleased = false
        private var pendingContinuations: [CheckedContinuation<Void, Never>] = []
        private var firstCallStartedContinuation: CheckedContinuation<Void, Never>?

        /// Suspends until the first `save(...)` call has started (returns
        /// immediately if it already has).
        func waitForFirstCallToStart() async {
            if saveCallCount > 0 { return }
            await withCheckedContinuation { continuation in
                self.firstCallStartedContinuation = continuation
            }
        }

        /// Releases every save call currently blocked, and lets any future
        /// call proceed without blocking.
        func releaseGate() {
            gateReleased = true
            let continuations = pendingContinuations
            pendingContinuations = []
            for continuation in continuations {
                continuation.resume()
            }
        }

        func save(_ game: Game, dungeonRun: DungeonRunSaveData?, slotId: String, playTime: TimeInterval) async throws {
            saveCallCount += 1
            let callIndex = saveCallCount
            events.append("start-\(callIndex)")
            firstCallStartedContinuation?.resume()
            firstCallStartedContinuation = nil
            if !gateReleased {
                await withCheckedContinuation { continuation in
                    self.pendingContinuations.append(continuation)
                }
            }
            events.append("finish-\(callIndex)")
        }

        func load(slotId: String) async throws -> LoadedSave { fatalError("unused") }
        func hasAnySave() -> Bool { false }
        func getPlayTime(slotId: String) async -> TimeInterval { 0 }
    }

    /// Always fails — used to prove the exit save error is caught and logged
    /// instead of propagating / crashing / getting silently dropped.
    private struct FailingGameSaveStorage: GameSaveStorage {
        struct SaveError: Error {}
        func save(_ game: Game, dungeonRun: DungeonRunSaveData?, slotId: String, playTime: TimeInterval) async throws {
            throw SaveError()
        }
        func load(slotId: String) async throws -> LoadedSave { fatalError("unused") }
        func hasAnySave() -> Bool { false }
        func getPlayTime(slotId: String) async -> TimeInterval { 0 }
    }

    private final class SpyDebugGameLogger: DebugGameLogger, @unchecked Sendable {
        private(set) var errorMessages: [String] = []
        func logGameSave(game: Game, playTime: TimeInterval) {}
        func logWorldTurn(_ outcome: WorldTurnOutcome) {}
        func logError(_ message: String) { errorMessages.append(message) }
        func logDebug(_ message: String) {}
    }

    // MARK: - AC-05 / ordering NFR: awaitInFlightSave() before the exit save

    func test_exitGame_awaitsPriorInFlightSave_beforeItsOwnSave() async {
        let gatedStorage = GatedGameSaveStorage()
        let (session, viewModel) = makeSessionAndViewModel(storage: gatedStorage, logger: SpyDebugGameLogger())

        // 1. Kick off an unrelated background save (e.g. what a farm activity
        //    would trigger) and let it start — it blocks on the gate.
        session.saveInBackground()
        await gatedStorage.waitForFirstCallToStart()
        XCTAssertEqual(gatedStorage.saveCallCount, 1)

        // 2. Ask the view model to exit while the first save is still in flight.
        let exitTask = Task { await viewModel.exitGame() }

        // 3. Give the exit path ample real time to (wrongly) race ahead of the
        //    still-blocked first save. A correct implementation awaits it via
        //    `awaitInFlightSave()` and never issues its own save call while the
        //    gate is closed.
        await waitUntil { gatedStorage.saveCallCount >= 2 }
        XCTAssertEqual(
            gatedStorage.saveCallCount, 1,
            "the exit save must not start until the prior in-flight save (awaitInFlightSave()) has finished"
        )

        // 4. Release the gate and let both saves finish.
        gatedStorage.releaseGate()
        await exitTask.value

        XCTAssertEqual(gatedStorage.saveCallCount, 2)
        XCTAssertEqual(
            gatedStorage.events,
            ["start-1", "finish-1", "start-2", "finish-2"],
            "the two saves must run strictly in sequence, not interleaved"
        )
    }

    // MARK: - AC-06 / AC-06b: failed save is caught, logged, and exitGame() still completes

    func test_exitGame_saveFailure_isLoggedAndExitStillCompletes() async {
        let logger = SpyDebugGameLogger()
        let (_, viewModel) = makeSessionAndViewModel(storage: FailingGameSaveStorage(), logger: logger)

        // If exitGame() rethrew or hung on failure, this line would either throw
        // (compile-time - it doesn't, proving no rethrow) or never return.
        await viewModel.exitGame()

        XCTAssertFalse(
            logger.errorMessages.isEmpty,
            "a failed exit save must be caught and logged via DebugGameLogger, not silently dropped"
        )
    }
}

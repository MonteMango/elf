//
//  GameDayStateViewModel_AdvanceToNextDayTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// T7 / AC-05, AC-06, AC-06b, AC-07: `GameDayStateViewModel.advanceToNextDay()`
/// must (1) await any prior in-flight background save before issuing its own
/// day-advance save, (2) catch and log a failed save via `DebugGameLogger`
/// instead of silently dropping it, and (3) keep `isAdvancingDay` raised for
/// the full duration of both awaits, clearing on both the success and the
/// failure path. Proven directly against `GameDayStateViewModel` + a real
/// `GameSession` wired with spy/gated fakes — no SwiftUI View involved (AC-07).
@MainActor
final class GameDayStateViewModel_AdvanceToNextDayTests: XCTestCase {

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
    ) -> (GameSession, GameDayStateViewModel) {
        withDependencies {
            $0.gameRepository = storage
            $0.debugGameLogger = logger
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
            $0.worldTurnRunner = ImmediateWorldTurnRunner()
        } operation: {
            let session = GameSession(game: makeGame())
            let viewModel = GameDayStateViewModel(session: session)
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

    /// Resolves immediately with no bot results — the day-advance flow doesn't
    /// need real world-turn simulation for these save-ordering/logging tests.
    private struct ImmediateWorldTurnRunner: WorldTurnRunner {
        func run(bots: [BotTurnContext], turnSeed: UInt64) async -> WorldTurnOutcome {
            WorldTurnOutcome(results: [])
        }
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

    /// Always fails — used to prove the day-advance save error is caught and
    /// logged instead of propagating / crashing / getting silently dropped.
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

    // MARK: - AC-05 / ordering NFR: awaitInFlightSave() before the day-advance save

    func test_advanceToNextDay_awaitsPriorInFlightSave_beforeItsOwnSave() async {
        let gatedStorage = GatedGameSaveStorage()
        let (session, viewModel) = makeSessionAndViewModel(storage: gatedStorage, logger: SpyDebugGameLogger())

        // 1. Kick off an unrelated background save (e.g. what a farm activity
        //    would trigger) and let it start — it blocks on the gate.
        session.saveInBackground()
        await gatedStorage.waitForFirstCallToStart()
        XCTAssertEqual(gatedStorage.saveCallCount, 1)

        // 2. Ask the view model to advance the day while the first save is
        //    still in flight.
        let advanceTask = Task { await viewModel.advanceToNextDay() }

        // 3. Give the day-advance path ample real time to (wrongly) race ahead
        //    of the still-blocked first save. A correct implementation awaits
        //    it via `awaitInFlightSave()` and never issues its own save call
        //    while the gate is closed.
        await waitUntil { gatedStorage.saveCallCount >= 2 }
        XCTAssertEqual(
            gatedStorage.saveCallCount, 1,
            "the day-advance save must not start until the prior in-flight save (awaitInFlightSave()) has finished"
        )

        // 4. Release the gate and let both saves finish.
        gatedStorage.releaseGate()
        await advanceTask.value

        XCTAssertEqual(gatedStorage.saveCallCount, 2)
        XCTAssertEqual(
            gatedStorage.events,
            ["start-1", "finish-1", "start-2", "finish-2"],
            "the two saves must run strictly in sequence, not interleaved"
        )
    }

    // MARK: - AC-06 / AC-06b: failed save is caught, logged, and the day-advance still completes

    func test_advanceToNextDay_saveFailure_isLoggedAndDayAdvanceStillCompletes() async {
        let logger = SpyDebugGameLogger()
        let (session, viewModel) = makeSessionAndViewModel(storage: FailingGameSaveStorage(), logger: logger)

        await viewModel.advanceToNextDay()

        XCTAssertFalse(
            logger.errorMessages.isEmpty,
            "a failed day-advance save must be caught and logged via DebugGameLogger, not silently dropped"
        )
        XCTAssertEqual(
            session.state.currentDay.dayNumber, 2,
            "the day transition must complete even when the save fails"
        )
        XCTAssertFalse(
            viewModel.isAdvancingDay,
            "isAdvancingDay must clear after a failed save, not stay stuck raised"
        )
    }

    // MARK: - AC-06: isAdvancingDay guard covers the full duration of both awaits

    func test_advanceToNextDay_isAdvancingDay_staysRaisedWhileSavingAndClearsOnSuccess() async {
        let gatedStorage = GatedGameSaveStorage()
        // `session` must stay alive for the whole test: `GameDayStateViewModel`
        // holds it only `weak`, so discarding the returned session with `_`
        // lets ARC deallocate it before `advanceToNextDay()` runs, silently
        // no-opping the method via its `guard let session` and hanging the
        // test forever on `waitForFirstCallToStart()`.
        let (session, viewModel) = makeSessionAndViewModel(storage: gatedStorage, logger: SpyDebugGameLogger())

        let advanceTask = Task { await viewModel.advanceToNextDay() }

        await gatedStorage.waitForFirstCallToStart()
        XCTAssertTrue(
            viewModel.isAdvancingDay,
            "isAdvancingDay must still be raised while the day-advance save is in flight"
        )

        gatedStorage.releaseGate()
        await advanceTask.value

        XCTAssertFalse(
            viewModel.isAdvancingDay,
            "isAdvancingDay must clear once the day-advance save completes"
        )
        withExtendedLifetime(session) {}
    }
}

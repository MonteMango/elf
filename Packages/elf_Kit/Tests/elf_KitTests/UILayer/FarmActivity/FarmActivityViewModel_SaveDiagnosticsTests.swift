//
//  FarmActivityViewModel_SaveDiagnosticsTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// T6 RED: `FarmActivityViewModel.performActivity()` must route both of its
/// save call sites (normal-completion + cancelled-path) through
/// `session.saveInBackground()` instead of `try? await session.save()`.
///
/// AC-05 — proven indirectly: `saveInBackground()` is the *only* path that
/// registers `session.awaitInFlightSave()` machinery and routes failures into
/// `DebugGameLogger`. Today, `performActivity()` calls `try? await
/// session.save()` directly, which silently swallows the error and never
/// touches `DebugGameLogger` — so a forced save failure is observably
/// invisible. Once the call sites switch to `saveInBackground()`, the same
/// forced failure becomes observable via the injected `DebugGameLogger` spy
/// after `awaitInFlightSave()` drains the coalesced background save.
///
/// AC-07 — the injected save failure must be observable via `DebugGameLogger`.
@MainActor
final class FarmActivityViewModel_SaveDiagnosticsTests: XCTestCase {

    // MARK: - Fakes

    /// Storage whose `save` always fails with a sentinel error, so a successful
    /// route-through to `DebugGameLogger` is unambiguous.
    private struct FailingStorage: GameSaveStorage {
        struct SentinelSaveError: Error, CustomStringConvertible {
            var description: String { "FarmActivityViewModel_SaveDiagnosticsTests.SentinelSaveError" }
        }
        func save(_ game: Game, dungeonRun: DungeonRunSaveData?, slotId: String, playTime: TimeInterval) async throws {
            throw SentinelSaveError()
        }
        func load(slotId: String) async throws -> LoadedSave { fatalError("unused") }
        func hasAnySave() -> Bool { false }
        func getPlayTime(slotId: String) async -> TimeInterval { 0 }
    }

    /// Spy that records every `logError` call so a test can assert the
    /// forced failure was actually surfaced.
    private final class SpyDebugGameLogger: DebugGameLogger, @unchecked Sendable {
        private(set) var loggedErrors: [String] = []
        func logGameSave(game: Game, playTime: TimeInterval) {}
        func logWorldTurn(_ outcome: WorldTurnOutcome) {}
        func logError(_ message: String) { loggedErrors.append(message) }
        func logDebug(_ message: String) {}
    }

    /// Deterministic, dependency-free `FarmActivityService` double — avoids
    /// pulling `DefaultFarmActivityService`'s live-only fish/foraging/mining
    /// sub-dependency tree (fish/gathering repositories require app-bootstrap
    /// `prepareDependencies`, unavailable in a unit test).
    private struct FakeFarmActivityService: FarmActivityService {
        func perform(activity: FarmActivity, currentExp: Int, expPerLevel: Int) -> FarmActivityResult {
            .fishing(FishingResult(
                caughtFish: [],
                skillProgress: SkillProgressData(
                    skillName: "Fishing", experienceGained: 0,
                    previousLevel: 1, previousExp: currentExp, previousExpToNext: expPerLevel,
                    newLevel: 1, newExp: currentExp, newExpToNext: expPerLevel
                )
            ))
        }
        func getAvailableItems(for activity: FarmActivity) -> [FarmActivityItem] { [] }
        func getSkillInfo(for activity: FarmActivity, exp: Int) -> FarmSkillInfo {
            FarmSkillInfo(title: "Fishing", level: 1, progress: 0, expInLevel: 0, expPerLevel: 100)
        }
    }

    /// Never has monsters to offer, so `checkMonsterAttack()` deterministically
    /// returns `false` regardless of the 20% RNG roll — keeps both tests below
    /// on the non-attack branch every run.
    private struct EmptyMonsterRepository: MonsterRepository {
        func getAll() -> [Monster] { [] }
        func getById(id: MonsterID) -> Monster? { nil }
        func getMonsters(world: WorldType, level: Int) -> [Monster] { [] }
    }

    /// Never invoked on the non-attack branch this suite exercises (guarded by
    /// `EmptyMonsterRepository` above) — stubbed only so `FarmActivityViewModel`'s
    /// eager `@Dependency(\.battleBuilder)` init-time resolution doesn't pull
    /// `DefaultBattleBuilder`'s own live-only sub-dependency tree (armor/items
    /// repositories) in a unit test.
    private struct StubBattleBuilder: BattleBuilder {
        func buildBattle(party: [BattlePartyMember], monsters: [Monster]) -> Battle? {
            fatalError("not exercised by the non-attack branch under test")
        }
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

    /// Builds a `GameSession` + `FarmActivityViewModel` pair with a
    /// forced-failing save path and a logger spy, both still in scope. Both
    /// live inside the `withDependencies` operation closure — `GameSession`'s
    /// and `FarmActivityViewModel`'s inits resolve `@Dependency` eagerly.
    private func makeSubjects(spy: SpyDebugGameLogger) -> (session: GameSession, viewModel: FarmActivityViewModel) {
        withDependencies {
            $0.gameRepository = FailingStorage()
            $0.debugGameLogger = spy
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
            $0.monsterRepository = EmptyMonsterRepository()
            $0.farmActivityService = FakeFarmActivityService()
            $0.battleBuilder = StubBattleBuilder()
            $0.progressionService = ElfProgressionService()
        } operation: {
            let session = GameSession(game: makeGame())
            let viewModel = FarmActivityViewModel(activity: .fishing, session: session)
            return (session, viewModel)
        }
    }

    // MARK: - AC-05 / AC-07 — normal-completion save (line 156)

    func testPerformActivity_NormalCompletion_ForcedSaveFailure_IsObservableViaDebugGameLogger() async {
        let spy = SpyDebugGameLogger()
        let (session, viewModel) = makeSubjects(spy: spy)

        await viewModel.performActivity()
        // If the call site routes through `saveInBackground()`, the save is
        // fire-and-forget — drain the coalesced background save before
        // asserting on its (failed) outcome.
        await session.awaitInFlightSave()

        XCTAssertTrue(
            spy.loggedErrors.contains { $0.contains("SentinelSaveError") },
            "Expected the forced save failure to be logged via DebugGameLogger.logError, got: \(spy.loggedErrors)"
        )
    }

    // MARK: - AC-05 / AC-07 — cancelled-path save (line 147)

    func testPerformActivity_CancelledPath_ForcedSaveFailure_IsObservableViaDebugGameLogger() async {
        let spy = SpyDebugGameLogger()
        let (session, viewModel) = makeSubjects(spy: spy)

        let task = Task { await viewModel.performActivity() }
        // Let `performActivity()` pass its synchronous pre-checks and enter
        // the 2-second animation `Task.sleep`, then cancel — `Task.sleep`
        // throws immediately on cancellation (swallowed by `try?`), so the
        // rest of the method runs its cancelled-path branch without waiting
        // out the full 2 seconds.
        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()
        await task.value
        await session.awaitInFlightSave()

        XCTAssertTrue(
            spy.loggedErrors.contains { $0.contains("SentinelSaveError") },
            "Expected the forced save failure to be logged via DebugGameLogger.logError, got: \(spy.loggedErrors)"
        )
    }
}

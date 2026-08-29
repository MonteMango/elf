//
//  GameDayViewModel_StartDungeonRunTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// AC-01 / AC-02 / AC-02b / AC-07 for T2: `GameDayViewModel.startDungeonRun()`
/// must start the dungeon run and debit `dungeonCost` action points exactly
/// once when AP is sufficient and a dungeon is available (AC-01); must be a
/// silent no-op (no run, zero AP debited) when AP is insufficient (AC-02) or
/// the dungeon pool is empty (AC-02b). Exercised directly against the VM
/// (AC-07) — no SwiftUI View involved — against a real `GameSession` so the
/// observable outcome asserted on is the actual player-visible session state
/// (`session.dungeonSession`, `session.state.player.actionPoints.current`).
@MainActor
final class GameDayViewModel_StartDungeonRunTests: XCTestCase {

    // MARK: - Fakes

    private struct NoOpStorage: GameSaveStorage {
        func save(_ game: Game, dungeonRun: DungeonRunSaveData?, slotId: String, playTime: TimeInterval) async throws {}
        func load(slotId: String) async throws -> LoadedSave { fatalError("unused") }
        func hasAnySave() -> Bool { false }
        func getPlayTime(slotId: String) async -> TimeInterval { 0 }
    }

    private struct FakeDungeonRepository: DungeonRepository {
        let dungeon: Dungeon?
        func getAll() -> [Dungeon] { dungeon.map { [$0] } ?? [] }
        func getById(id: DungeonID) -> Dungeon? { dungeon?.id == id ? dungeon : nil }
        func randomDungeon() -> Dungeon? { dungeon }
    }

    private func makeDungeon() -> Dungeon {
        let roomId = DungeonRoomID(rawValue: UUID())
        let room = DungeonRoom(id: roomId, title: "Entry", kind: .combat([]), nextRoomIds: [])
        return Dungeon(
            id: DungeonID(rawValue: UUID()), title: "Test Dungeon", description: "",
            type: .onePath, world: .upper, backgroundImageName: "bg",
            entryRoomIds: [roomId], rooms: [room]
        )
    }

    // MARK: - Fixtures

    private func makeGame(playerActionPoints: ActionPoints) -> Game {
        let player = TestFixtures.elf(actionPoints: playerActionPoints)
        let members = [player] + (0..<(House.membersCount - 1)).map { _ in TestFixtures.elf() }
        let houses: [House] = (0..<Game.housesCount).map { i in
            House(name: "H\(i)", logoImageName: "logo", members: members)
        }
        let calendar = [GameDay(dayNumber: 1, dayType: .normal)]
        let gameState = GameState(currentDay: calendar[0], calendar: calendar)
        return Game(houses: houses, gameState: gameState, playerHouseIndex: 0, playerMemberIndex: 0)
    }

    /// Both `GameSession` and `GameDayViewModel` resolve their `@Dependency`
    /// properties eagerly at init, so both must be constructed inside the same
    /// `withDependencies` scope (mirrors `FarmActivityViewModel_SaveDiagnosticsTests`).
    private func makeSessionAndViewModel(
        playerActionPoints: ActionPoints,
        dungeonRepository: FakeDungeonRepository
    ) -> (session: GameSession, viewModel: GameDayViewModel) {
        withDependencies {
            $0.gameRepository = NoOpStorage()
            $0.dungeonRepository = dungeonRepository
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
            $0.itemsRepository = ElfItemsRepository(heroItems: .empty)
            $0.equippedSlotResolver = DefaultHeroEquippedSlotResolver()
            $0.progressionService = ElfProgressionService()
            $0.equipmentQueryService = ElfEquipmentQueryService()
        } operation: {
            let session = GameSession(game: makeGame(playerActionPoints: playerActionPoints))
            let viewModel = GameDayViewModel(session: session)
            return (session, viewModel)
        }
    }

    /// `GameSession.startDungeonSession(...)` (reached via `startDungeonRun()`)
    /// resolves `dungeonLifecycleMutator`/`dungeonRepository` freshly at call
    /// time rather than snapshotting them at init, so the act step must also
    /// run inside a `withDependencies` scope providing `dungeonRepository`
    /// (mirrors `GameSession_DungeonLifecycleDelegationTests`).
    private func startDungeonRun(
        _ viewModel: GameDayViewModel,
        dungeonRepository: FakeDungeonRepository
    ) -> (dungeonId: DungeonID, allyIds: [ElfID])? {
        withDependencies {
            $0.dungeonRepository = dungeonRepository
        } operation: {
            viewModel.startDungeonRun()
        }
    }

    // MARK: - AC-01: sufficient AP + dungeon available

    func testStartDungeonRun_SufficientAPAndDungeonAvailable_StartsRunAndDebitsCostExactlyOnce() {
        let dungeon = makeDungeon()
        let dungeonRepository = FakeDungeonRepository(dungeon: dungeon)
        // 250 (well above dungeonCost*2 = 200) so a double-spend bug would
        // land on 50, not 0 — `current: 100` couldn't distinguish a single
        // spend from a double spend, since ActionPoints.spend's own guard
        // rejects the second call once current is already 0 (review finding).
        let (session, viewModel) = makeSessionAndViewModel(
            playerActionPoints: .unsafeCreate(current: 250, maximum: 250),
            dungeonRepository: dungeonRepository
        )

        let result = startDungeonRun(viewModel, dungeonRepository: dungeonRepository)

        XCTAssertNotNil(session.dungeonSession, "AC-01: run must be started for the available dungeon")
        XCTAssertEqual(
            result?.dungeonId, dungeon.id,
            "AC-01: the returned dungeonId must match the dungeon the run was actually started for — "
                + "this is the contract GameDayScreen's navigation is wired to"
        )
        XCTAssertEqual(
            session.state.player.actionPoints.current, 150,
            "AC-01: dungeonCost (100) must be debited exactly once from the player's action points"
        )
    }

    // MARK: - AC-02: insufficient AP

    func testStartDungeonRun_InsufficientAP_IsNoOpWithZeroDebit() {
        let dungeon = makeDungeon()
        let dungeonRepository = FakeDungeonRepository(dungeon: dungeon)
        let (session, viewModel) = makeSessionAndViewModel(
            playerActionPoints: .unsafeCreate(current: 50, maximum: 100),
            dungeonRepository: dungeonRepository
        )

        let result = startDungeonRun(viewModel, dungeonRepository: dungeonRepository)

        XCTAssertNil(session.dungeonSession, "AC-02: no run must be started when AP is insufficient")
        XCTAssertNil(result, "AC-02: the no-op path must return nil — GameDayScreen navigates on a non-nil result")
        XCTAssertEqual(
            session.state.player.actionPoints.current, 50,
            "AC-02: no action points must be debited on the insufficient-AP no-op path"
        )
    }

    // MARK: - AC-02b: empty dungeon pool

    func testStartDungeonRun_EmptyDungeonPool_IsNoOpWithZeroDebit() {
        let dungeonRepository = FakeDungeonRepository(dungeon: nil)
        let (session, viewModel) = makeSessionAndViewModel(
            playerActionPoints: .unsafeCreate(current: 100, maximum: 100),
            dungeonRepository: dungeonRepository
        )

        let result = startDungeonRun(viewModel, dungeonRepository: dungeonRepository)

        XCTAssertNil(session.dungeonSession, "AC-02b: no run must be started when the dungeon pool is empty")
        XCTAssertNil(result, "AC-02b: the no-op path must return nil — GameDayScreen navigates on a non-nil result")
        XCTAssertEqual(
            session.state.player.actionPoints.current, 100,
            "AC-02b: no action points must be debited when the dungeon pool is empty"
        )
    }
}

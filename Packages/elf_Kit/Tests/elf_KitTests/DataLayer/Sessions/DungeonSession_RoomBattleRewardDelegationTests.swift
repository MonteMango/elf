//
//  DungeonSession_RoomBattleRewardDelegationTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// AC-06 real-delegation check for T14: `DungeonSession.applyBattleOutcome`,
/// `concludeRoomBattle`, and `clearPendingRewards` must each reduce to a single
/// call into the injected `RoomBattleRewardMutator` — not reimplement the rule
/// inline. Proven here with a spy mutator whose canned return values are
/// deliberately impossible for `DungeonSession` to have produced on its own
/// (arbitrary sentinel ids / values): if the session's observable state exactly
/// mirrors the spy's output, the facade must be *using* the injected value
/// rather than computing its own.
@MainActor
final class DungeonSession_RoomBattleRewardDelegationTests: XCTestCase {

    // MARK: - Spy

    private final class SpyRoomBattleRewardMutator: RoomBattleRewardMutator, @unchecked Sendable {
        var applyBattleOutcomeCallCount = 0
        var concludeRoomBattleCallCount = 0
        var clearPendingRewardsCallCount = 0

        let sentinelVitals: [ElfID: DungeonElfVitals]
        let sentinelClearedRoomIds: Set<DungeonRoomID>
        let sentinelConcludeResult: RoomBattleConcludeResult
        let sentinelClearedLedger: DungeonRunRewards

        init(
            sentinelVitals: [ElfID: DungeonElfVitals],
            sentinelClearedRoomIds: Set<DungeonRoomID>,
            sentinelConcludeResult: RoomBattleConcludeResult,
            sentinelClearedLedger: DungeonRunRewards
        ) {
            self.sentinelVitals = sentinelVitals
            self.sentinelClearedRoomIds = sentinelClearedRoomIds
            self.sentinelConcludeResult = sentinelConcludeResult
            self.sentinelClearedLedger = sentinelClearedLedger
        }

        func applyBattleOutcome(
            finalLeftTeam: [CombatantSnapshot],
            outcome: BattleOutcome,
            currentRoomId: DungeonRoomID?,
            roomVitals: [ElfID: DungeonElfVitals],
            clearedRoomIds: Set<DungeonRoomID>
        ) -> RoomBattleOutcomeResult {
            applyBattleOutcomeCallCount += 1
            return RoomBattleOutcomeResult(roomVitals: sentinelVitals, clearedRoomIds: sentinelClearedRoomIds)
        }

        func concludeRoomBattle(
            outcome: BattleOutcome,
            room: DungeonRoom?,
            wasAlreadyCleared: Bool,
            pendingRewards: DungeonRunRewards,
            playerCurrentExp: Int
        ) -> RoomBattleConcludeResult {
            concludeRoomBattleCallCount += 1
            return sentinelConcludeResult
        }

        func clearPendingRewards() -> DungeonRunRewards {
            clearPendingRewardsCallCount += 1
            return sentinelClearedLedger
        }
    }

    // MARK: - Fixtures

    private let dungeonId = DungeonID(rawValue: UUID())
    private let roomAId = DungeonRoomID(rawValue: UUID())
    private let sentinelRoomId = DungeonRoomID(rawValue: UUID())

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

    private func makeSession(spy: SpyRoomBattleRewardMutator) -> DungeonSession {
        let hero = TestFixtures.elf()
        let ally = TestFixtures.elf()
        let others = (0..<(House.membersCount - 2)).map { _ in TestFixtures.elf() }
        let members = [hero, ally] + others
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
        let store = GameStore(from: game)
        return withDependencies {
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
            $0.roomBattleRewardMutator = spy
        } operation: {
            DungeonSession(gameStore: store, dungeonId: dungeonId, allyIds: [ally.id])
        }
    }

    // MARK: - applyBattleOutcome delegates

    func testApplyBattleOutcome_DelegatesToInjectedMutator() {
        let sentinelElfId = ElfID()
        let spy = SpyRoomBattleRewardMutator(
            sentinelVitals: [sentinelElfId: DungeonElfVitals(hp: 999, mp: 999)],
            sentinelClearedRoomIds: [sentinelRoomId],
            sentinelConcludeResult: RoomBattleConcludeResult(
                pendingRewards: .empty,
                manualBattleResult: ManualBattleResult(
                    outcome: .victory, experienceGained: 0, drops: [],
                    previousLevel: 1, previousExp: 0, previousExpToNext: 0,
                    newLevel: 1, newExp: 0, newExpToNext: 0
                )
            ),
            sentinelClearedLedger: .empty
        )
        let session = makeSession(spy: spy)

        session.applyBattleOutcome(finalLeftTeam: [], outcome: .victory)

        XCTAssertEqual(spy.applyBattleOutcomeCallCount, 1)
        // The session's post-call state is exactly the spy's sentinel — proof it
        // wrote back the mutator's result rather than computing its own.
        XCTAssertEqual(session.roomVitals[sentinelElfId], DungeonElfVitals(hp: 999, mp: 999))
        XCTAssertTrue(session.clearedRoomIds.contains(sentinelRoomId))
    }

    // MARK: - concludeRoomBattle delegates

    func testConcludeRoomBattle_DelegatesToInjectedMutatorAndReturnsItsResult() {
        let sentinelResult = ManualBattleResult(
            outcome: .victory, experienceGained: 12345, drops: [],
            previousLevel: 1, previousExp: 0, previousExpToNext: 0,
            newLevel: 1, newExp: 0, newExpToNext: 0
        )
        let sentinelLedger = DungeonRunRewards(experience: 6789)
        let spy = SpyRoomBattleRewardMutator(
            sentinelVitals: [:],
            sentinelClearedRoomIds: [],
            sentinelConcludeResult: RoomBattleConcludeResult(
                pendingRewards: sentinelLedger,
                manualBattleResult: sentinelResult
            ),
            sentinelClearedLedger: .empty
        )
        let session = makeSession(spy: spy)

        let result = session.concludeRoomBattle(outcome: .victory, finalLeftTeam: [])

        XCTAssertEqual(spy.concludeRoomBattleCallCount, 1)
        // Returned result is exactly the sentinel — the session did not
        // recompute experience/drops itself.
        XCTAssertEqual(result.experienceGained, 12345)
        XCTAssertEqual(session.pendingRewards.experience, 6789)
    }

    // MARK: - clearPendingRewards delegates

    func testClearPendingRewards_DelegatesToInjectedMutator() {
        let spy = SpyRoomBattleRewardMutator(
            sentinelVitals: [:],
            sentinelClearedRoomIds: [],
            sentinelConcludeResult: RoomBattleConcludeResult(
                pendingRewards: .empty,
                manualBattleResult: ManualBattleResult(
                    outcome: .victory, experienceGained: 0, drops: [],
                    previousLevel: 1, previousExp: 0, previousExpToNext: 0,
                    newLevel: 1, newExp: 0, newExpToNext: 0
                )
            ),
            sentinelClearedLedger: .empty
        )
        let session = makeSession(spy: spy)

        session.clearPendingRewards()

        XCTAssertEqual(spy.clearPendingRewardsCallCount, 1)
    }
}

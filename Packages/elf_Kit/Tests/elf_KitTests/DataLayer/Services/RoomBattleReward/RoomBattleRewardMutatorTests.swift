//
//  RoomBattleRewardMutatorTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests the `RoomBattleRewardMutator` extracted from `DungeonSession`'s
/// room-battle-reward rule family (T14): `applyBattleOutcome`,
/// `concludeRoomBattle`, and `clearPendingRewards`. Exercised directly against
/// the injected type (via `@Dependency(\.roomBattleRewardMutator)`), independent
/// of `DungeonSession` — `DungeonSession_BattleFlowTests` covers
/// `applyBattleOutcome` through the facade and must keep passing unchanged.
final class RoomBattleRewardMutatorTests: XCTestCase {

    // MARK: - Fixtures

    private let roomAId = DungeonRoomID(rawValue: UUID())
    private let monsterId = MonsterID(rawValue: UUID())

    /// Fake reward calculator returning a fixed roll — the mutator's job is to
    /// decide *whether* to accrue rewards (first clear only), not to compute them.
    private struct FakeDungeonRewardCalculator: DungeonRewardCalculator {
        let rewards: [HuntRewards]
        func roomRewards(monsters: [MonsterRef]) -> [HuntRewards] { rewards }
    }

    /// Fake drop service returning a fixed drop per call, tagged by `didWin` so
    /// tests can assert the mutator forwards the outcome correctly.
    private struct FakeDropService: DropService {
        func convertToDropItems(rewards: HuntRewards, didWin: Bool) -> [DropItem] {
            guard didWin else { return [] }
            return [DropItem(itemType: .material, name: "Fake Drop", icon: "icon", tier: .common)]
        }
    }

    private func makeMutator(rewards: [HuntRewards] = []) -> any RoomBattleRewardMutator {
        withDependencies {
            $0.dungeonRewardCalculator = FakeDungeonRewardCalculator(rewards: rewards)
            $0.dropService = FakeDropService()
        } operation: {
            @Dependency(\.roomBattleRewardMutator) var mutator
            return mutator
        }
    }

    /// `concludeRoomBattle` resolves its reward-calculator/drop-service
    /// dependencies lazily (not at mutator construction — mirrors
    /// `DungeonSession`'s original "don't eagerly pull live-only deps" rule,
    /// see `DefaultRoomBattleRewardMutator`), so the fakes must be in scope for
    /// the *call*, not just for `makeMutator()`.
    private func concludeRoomBattle(
        outcome: BattleOutcome,
        room: DungeonRoom?,
        wasAlreadyCleared: Bool,
        pendingRewards: DungeonRunRewards,
        playerCurrentExp: Int,
        rewards: [HuntRewards]
    ) -> RoomBattleConcludeResult {
        withDependencies {
            $0.dungeonRewardCalculator = FakeDungeonRewardCalculator(rewards: rewards)
            $0.dropService = FakeDropService()
            $0.progressionService = ElfProgressionService()
        } operation: {
            @Dependency(\.roomBattleRewardMutator) var mutator
            return mutator.concludeRoomBattle(
                outcome: outcome,
                room: room,
                wasAlreadyCleared: wasAlreadyCleared,
                pendingRewards: pendingRewards,
                playerCurrentExp: playerCurrentExp
            )
        }
    }

    private func makeRoom(monsterCount: Int = 1) -> DungeonRoom {
        DungeonRoom(
            id: roomAId,
            title: "Room",
            kind: .combat([MonsterRef(monsterId: monsterId, count: monsterCount)]),
            nextRoomIds: []
        )
    }

    // MARK: - applyBattleOutcome

    func testApplyBattleOutcome_HeroSurvives_UpdatesVitalsAndClearsRoom() {
        let mutator = makeMutator()
        let heroId = ElfID()
        let allyId = ElfID()

        let result = mutator.applyBattleOutcome(
            finalLeftTeam: [
                snapshot(elfId: heroId, hp: 30, mp: 5),
                snapshot(elfId: allyId, hp: 0, mp: 0)
            ],
            outcome: .victory,
            currentRoomId: roomAId,
            roomVitals: [:],
            clearedRoomIds: []
        )

        XCTAssertEqual(result.roomVitals[heroId], DungeonElfVitals(hp: 30, mp: 5))
        XCTAssertEqual(result.roomVitals[allyId], DungeonElfVitals(hp: 0, mp: 0))
        XCTAssertTrue(result.clearedRoomIds.contains(roomAId))
    }

    func testApplyBattleOutcome_Defeat_DoesNotClearRoom() {
        let mutator = makeMutator()
        let heroId = ElfID()

        let result = mutator.applyBattleOutcome(
            finalLeftTeam: [snapshot(elfId: heroId, hp: 0, mp: 0)],
            outcome: .defeat,
            currentRoomId: roomAId,
            roomVitals: [:],
            clearedRoomIds: []
        )

        XCTAssertFalse(result.clearedRoomIds.contains(roomAId))
    }

    func testApplyBattleOutcome_NegativeHPClampedToZero() {
        let mutator = makeMutator()
        let heroId = ElfID()

        let result = mutator.applyBattleOutcome(
            finalLeftTeam: [snapshot(elfId: heroId, hp: -25, mp: -3)],
            outcome: .defeat,
            currentRoomId: roomAId,
            roomVitals: [:],
            clearedRoomIds: []
        )

        XCTAssertEqual(result.roomVitals[heroId], DungeonElfVitals(hp: 0, mp: 0))
    }

    // MARK: - concludeRoomBattle

    /// AC-04-adjacent ordering: the room's rewards are rolled from the state as
    /// it stood *before* this battle's mutation (the caller passes
    /// `wasAlreadyCleared`/`room` captured pre-mutation) — a first clear accrues
    /// exactly the fake calculator's roll into the ledger and into the overlay.
    func testConcludeRoomBattle_FirstClear_AccruesRewardsAndReturnsThem() {
        let fakeReward = HuntRewards(experience: 50, materials: [])

        let result = concludeRoomBattle(
            outcome: .victory,
            room: makeRoom(),
            wasAlreadyCleared: false,
            pendingRewards: .empty,
            playerCurrentExp: 0,
            rewards: [fakeReward]
        )

        XCTAssertEqual(result.pendingRewards.experience, 50)
        XCTAssertEqual(result.manualBattleResult.experienceGained, 50)
        XCTAssertEqual(result.manualBattleResult.drops.count, 1)
    }

    func testConcludeRoomBattle_AlreadyCleared_GrantsNoRewards() {
        let fakeReward = HuntRewards(experience: 50, materials: [])

        let result = concludeRoomBattle(
            outcome: .victory,
            room: makeRoom(),
            wasAlreadyCleared: true,
            pendingRewards: .empty,
            playerCurrentExp: 0,
            rewards: [fakeReward]
        )

        XCTAssertEqual(result.pendingRewards.experience, 0)
        XCTAssertEqual(result.manualBattleResult.experienceGained, 0)
        XCTAssertTrue(result.manualBattleResult.drops.isEmpty)
    }

    func testConcludeRoomBattle_Defeat_GrantsNoRewardsEvenOnFirstClear() {
        let fakeReward = HuntRewards(experience: 50, materials: [])

        let result = concludeRoomBattle(
            outcome: .defeat,
            room: makeRoom(),
            wasAlreadyCleared: false,
            pendingRewards: .empty,
            playerCurrentExp: 0,
            rewards: [fakeReward]
        )

        XCTAssertEqual(result.pendingRewards.experience, 0)
        XCTAssertEqual(result.manualBattleResult.experienceGained, 0)
    }

    /// Rewards already banked in earlier rooms this run stay in the ledger —
    /// the overlay reports only *this room's* incremental XP gain.
    func testConcludeRoomBattle_BanksOnTopOfExistingPendingRewards() {
        let fakeReward = HuntRewards(experience: 30, materials: [])

        let result = concludeRoomBattle(
            outcome: .victory,
            room: makeRoom(),
            wasAlreadyCleared: false,
            pendingRewards: DungeonRunRewards(experience: 20),
            playerCurrentExp: 0,
            rewards: [fakeReward]
        )

        XCTAssertEqual(result.pendingRewards.experience, 50) // 20 banked + 30 this room
        XCTAssertEqual(result.manualBattleResult.experienceGained, 30) // only this room's gain
    }

    // MARK: - clearPendingRewards

    func testClearPendingRewards_ReturnsEmptyLedger() {
        let mutator = makeMutator()

        let result = mutator.clearPendingRewards()

        XCTAssertEqual(result, DungeonRunRewards.empty)
    }

    // MARK: - Helpers

    private func snapshot(elfId: ElfID, hp: Int, mp: Int) -> CombatantSnapshot {
        CombatantSnapshot(
            source: .elf(elfId),
            name: "Elf", imageName: "elf_1", combatantType: .elf,
            currentHP: hp, currentMP: mp, currentEP: 0, maxEP: 0,
            baseHeroAttributes: HeroAttributes(),
            attacks: [], defensePoints: 0, armorValues: [:]
        )
    }
}

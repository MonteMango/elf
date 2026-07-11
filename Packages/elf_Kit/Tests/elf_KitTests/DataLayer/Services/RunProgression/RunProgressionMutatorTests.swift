//
//  RunProgressionMutatorTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests the `RunProgressionMutator` extracted from `DungeonSession`'s
/// run-progression rule family (T13): `beginRun`, `restoreQuarter`, `apply(_:)`,
/// and `moveSquadToNextRoom`. Exercised directly against the injected type
/// (via `@Dependency(\.runProgressionMutator)`), independent of `DungeonSession`
/// — `DungeonSession_BattleFlowTests` covers the same rules through the facade
/// and must keep passing unchanged.
final class RunProgressionMutatorTests: XCTestCase {

    // MARK: - Fixtures

    private let roomAId = DungeonRoomID(rawValue: UUID())
    private let roomBId = DungeonRoomID(rawValue: UUID())

    private func makeMutator() -> any RunProgressionMutator {
        withDependencies { _ in
            // No overrides: exercise the live implementation.
        } operation: {
            @Dependency(\.runProgressionMutator) var mutator
            return mutator
        }
    }

    // MARK: - beginRun

    func testBeginRun_SeedsFullVitalsAndPlacesSquadInEntryRoom() {
        let mutator = makeMutator()
        let hero = TestFixtures.elf()
        let ally = TestFixtures.elf()

        let result = mutator.beginRun(
            entryRoomId: roomAId,
            heroId: hero.id,
            allyIds: [ally.id],
            squadElves: [hero, ally]
        )

        XCTAssertEqual(result.elfLocations[hero.id], roomAId)
        XCTAssertEqual(result.elfLocations[ally.id], roomAId)
        XCTAssertEqual(result.roomVitals[hero.id], DungeonElfVitals(hp: Int(hero.maxHP), mp: Int(hero.maxMP)))
        XCTAssertEqual(result.roomVitals[ally.id], DungeonElfVitals(hp: Int(ally.maxHP), mp: Int(ally.maxMP)))
    }

    // MARK: - restoreQuarter

    func testRestoreQuarter_HealsLivingByQuarterAndClampsToMax() {
        let mutator = makeMutator()
        let hero = TestFixtures.elf()
        // Hero down to 30/80 HP, 5/20 MP (fixture maxHP=80, maxMP=20).
        let vitals: [ElfID: DungeonElfVitals] = [hero.id: DungeonElfVitals(hp: 30, mp: 5)]

        let updated = mutator.restoreQuarter(squadElves: [hero], roomVitals: vitals)

        // +25% of max → +20 HP, +5 MP.
        XCTAssertEqual(updated[hero.id], DungeonElfVitals(hp: 50, mp: 10))
    }

    func testRestoreQuarter_DoesNotReviveDownedMembers() {
        let mutator = makeMutator()
        let ally = TestFixtures.elf()
        let vitals: [ElfID: DungeonElfVitals] = [ally.id: DungeonElfVitals(hp: 0, mp: 0)]

        let updated = mutator.restoreQuarter(squadElves: [ally], roomVitals: vitals)

        XCTAssertEqual(updated[ally.id], DungeonElfVitals(hp: 0, mp: 0))
    }

    // MARK: - apply(_:)

    func testApply_FullRestore_HealsLivingAndClearsRoom() {
        let mutator = makeMutator()
        let hero = TestFixtures.elf()
        let ally = TestFixtures.elf()
        let vitals: [ElfID: DungeonElfVitals] = [
            hero.id: DungeonElfVitals(hp: 10, mp: 2),
            ally.id: DungeonElfVitals(hp: 0, mp: 0)
        ]

        let result = mutator.apply(
            DungeonEventOutcome(restore: .full, clearsRoom: true),
            squadElves: [hero, ally],
            roomVitals: vitals,
            currentRoomId: roomAId,
            clearedRoomIds: []
        )

        XCTAssertEqual(result.roomVitals[hero.id], DungeonElfVitals(hp: Int(hero.maxHP), mp: Int(hero.maxMP)))
        XCTAssertEqual(result.roomVitals[ally.id], DungeonElfVitals(hp: 0, mp: 0)) // no revive
        XCTAssertTrue(result.clearedRoomIds.contains(roomAId))
    }

    func testApply_NoRestore_LeavesVitalsUntouchedAndDoesNotClearRoom() {
        let mutator = makeMutator()
        let hero = TestFixtures.elf()
        let vitals: [ElfID: DungeonElfVitals] = [hero.id: DungeonElfVitals(hp: 10, mp: 2)]

        let result = mutator.apply(
            DungeonEventOutcome(restore: nil, clearsRoom: false),
            squadElves: [hero],
            roomVitals: vitals,
            currentRoomId: roomAId,
            clearedRoomIds: []
        )

        XCTAssertEqual(result.roomVitals[hero.id], DungeonElfVitals(hp: 10, mp: 2))
        XCTAssertFalse(result.clearedRoomIds.contains(roomAId))
    }

    // MARK: - moveSquadToNextRoom

    func testMoveSquadToNextRoom_AdvancesEveryoneToNextRoom() {
        let mutator = makeMutator()
        let hero = TestFixtures.elf()
        let ally = TestFixtures.elf()
        let locations: [ElfID: DungeonRoomID] = [hero.id: roomAId, ally.id: roomAId]

        let updated = mutator.moveSquadToNextRoom(nextRoomId: roomBId, elfLocations: locations)

        XCTAssertEqual(updated[hero.id], roomBId)
        XCTAssertEqual(updated[ally.id], roomBId)
    }

    func testMoveSquadToNextRoom_NoNextRoom_IsANoOp() {
        let mutator = makeMutator()
        let hero = TestFixtures.elf()
        let locations: [ElfID: DungeonRoomID] = [hero.id: roomBId]

        let updated = mutator.moveSquadToNextRoom(nextRoomId: nil, elfLocations: locations)

        XCTAssertEqual(updated, locations)
    }
}

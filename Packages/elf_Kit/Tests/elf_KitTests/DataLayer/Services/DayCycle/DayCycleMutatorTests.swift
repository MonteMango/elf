//
//  DayCycleMutatorTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests the `DayCycleMutator` extracted from `GameSession`'s Day Management
/// rule family (T10): all-elves AP reset and global-buff expiry. Exercised
/// directly against the injected type (via `@Dependency(\.dayCycleMutator)`),
/// independent of `GameSession` — `GameSession_WorldTurnTests` covers the
/// AP-reset rule through the facade and must keep passing unchanged.
final class DayCycleMutatorTests: XCTestCase {

    // MARK: - Fixtures

    private func makeMutator(buffs: [Buff] = []) -> any DayCycleMutator {
        withDependencies {
            $0.buffsRepository = ElfBuffsRepository(buffsData: BuffsData(version: "test", buffs: buffs))
        } operation: {
            @Dependency(\.dayCycleMutator) var mutator
            return mutator
        }
    }

    /// One house of exactly `House.membersCount` elves (a domain invariant),
    /// with the first two members distinguished by id for assertions.
    private func makeHouse(elf1: ElfInfo, elf2: ElfInfo) -> House {
        var members = [elf1, elf2]
        while members.count < House.membersCount {
            members.append(TestFixtures.elf())
        }
        return House(name: "H0", logoImageName: "logo", members: members)
    }

    // MARK: - AP reset

    func testAdvanceDay_ResetsActionPointsForAllElves() {
        let mutator = makeMutator()
        let elf1 = TestFixtures.elf(actionPoints: .unsafeCreate(current: 20, maximum: 100))
        let elf2 = TestFixtures.elf(actionPoints: .unsafeCreate(current: 0, maximum: 100))
        let house = makeHouse(elf1: elf1, elf2: elf2)

        let updated = mutator.advanceDay(houses: [house], toDayNumber: 2)

        XCTAssertEqual(updated[0].members[0].actionPoints.current, 100)
        XCTAssertEqual(updated[0].members[1].actionPoints.current, 100)
    }

    // MARK: - Buff expiry

    func testAdvanceDay_ExpiresGlobalBuffPastDuration() {
        let buffId = BuffID()
        let buff = Buff(
            id: buffId, title: "T", imageName: "i", description: "d",
            polarity: .positive, scope: .global, durationDays: 3,
            stackingRule: .refresh, effects: []
        )
        let mutator = makeMutator(buffs: [buff])
        var elf1 = TestFixtures.elf()
        // Applied on day 1, duration 3 → expires once currentDayNumber - appliedOnDay >= 3.
        elf1.globalBuffs = [AppliedBuff(buffId: buffId, appliedOnDay: 1)]
        let house = makeHouse(elf1: elf1, elf2: TestFixtures.elf())

        let updated = mutator.advanceDay(houses: [house], toDayNumber: 4)

        XCTAssertTrue(updated[0].members[0].globalBuffs.isEmpty)
    }

    func testAdvanceDay_KeepsGlobalBuffStillWithinDuration() {
        let buffId = BuffID()
        let buff = Buff(
            id: buffId, title: "T", imageName: "i", description: "d",
            polarity: .positive, scope: .global, durationDays: 3,
            stackingRule: .refresh, effects: []
        )
        let mutator = makeMutator(buffs: [buff])
        var elf1 = TestFixtures.elf()
        elf1.globalBuffs = [AppliedBuff(buffId: buffId, appliedOnDay: 1)]
        let house = makeHouse(elf1: elf1, elf2: TestFixtures.elf())

        let updated = mutator.advanceDay(houses: [house], toDayNumber: 3)

        XCTAssertEqual(updated[0].members[0].globalBuffs.count, 1)
    }
}

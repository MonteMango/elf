//
//  WorldTurnMutatorTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests the `WorldTurnMutator` extracted from `GameSession`'s World Turn
/// logic (T12): per-bot exp/drops/AP application, gated by the AC-04
/// invariant #2 roster-reshuffle guard (a result's `slot.id` must still
/// match the elf occupying that slot). Exercised directly against the
/// injected type (via `@Dependency(\.worldTurnMutator)`), independent of
/// `GameSession` — `GameSession_WorldTurnTests` covers the same behaviour
/// through the facade and must keep passing unchanged.
final class WorldTurnMutatorTests: XCTestCase {

    // MARK: - Fixtures

    private func makeMutator() -> any WorldTurnMutator {
        withDependencies {
            $0.inventoryService = ElfInventoryService()
            $0.rosterProgressionMutator = DefaultRosterProgressionMutator()
        } operation: {
            @Dependency(\.worldTurnMutator) var mutator
            return mutator
        }
    }

    /// One house of exactly `House.membersCount` elves (a domain invariant).
    private func makeHouse(members: [ElfInfo]) -> House {
        var members = members
        while members.count < House.membersCount {
            members.append(TestFixtures.elf())
        }
        return House(name: "H0", logoImageName: "logo", members: members)
    }

    private func botResult(
        houseIndex: Int,
        memberIndex: Int,
        id: ElfID,
        exp: Int = 0,
        materials: [MaterialReward] = [],
        apSpent: Int = 0
    ) -> BotTurnResult {
        BotTurnResult(
            slot: RosterSlot(houseIndex: houseIndex, memberIndex: memberIndex, id: id),
            experienceGained: exp,
            materials: materials,
            weapons: [],
            armor: [],
            actionPointsSpent: apSpent,
            battles: []
        )
    }

    // MARK: - AC-04 invariant #2: roster-reshuffle guard

    /// Named regression test for the AC-04 invariant #2 roster-reshuffle
    /// guard: if a result's `slot.id` no longer matches the elf actually
    /// occupying `(houseIndex, memberIndex)` (the roster reshuffled between
    /// snapshot and apply), the mutator must skip that result entirely —
    /// no exp, no drops, no AP spend.
    func testApplyWorldTurn_rosterReshuffleGuard_skipsMutationWhenSlotIdNoLongerMatchesRoster() {
        let mutator = makeMutator()
        let bot = TestFixtures.elf(actionPoints: .unsafeCreate(current: 100, maximum: 100))
        let house = makeHouse(members: [bot])
        // A slot whose id does not match the elf actually living there.
        let result = botResult(
            houseIndex: 0, memberIndex: 0, id: ElfID(),
            exp: 999, materials: [MaterialReward(id: MaterialID(), amount: 5)], apSpent: 40
        )

        let updated = mutator.applyWorldTurn(WorldTurnOutcome(results: [result]), to: [house])

        let updatedBot = updated[0].members[0]
        XCTAssertEqual(updatedBot.currentExp, 0)
        XCTAssertEqual(updatedBot.actionPoints.current, 100)
        XCTAssertTrue(updatedBot.inventory.materials.isEmpty)
    }

    func testApplyWorldTurn_appliesExpDropsAndAP_whenSlotIdMatchesRoster() {
        let bot = TestFixtures.elf(actionPoints: .unsafeCreate(current: 100, maximum: 100))
        let house = makeHouse(members: [bot])
        let result = botResult(
            houseIndex: 0, memberIndex: 0, id: bot.id,
            exp: 50, materials: [MaterialReward(id: MaterialID(), amount: 3)], apSpent: 40
        )

        // `addDrops` resolves `inventoryService` lazily at call time (see
        // DefaultRosterProgressionMutator), so the override must stay in
        // scope for the `applyWorldTurn` call itself, not just mutator setup.
        let updated = withDependencies {
            $0.inventoryService = ElfInventoryService()
            $0.rosterProgressionMutator = DefaultRosterProgressionMutator()
        } operation: {
            @Dependency(\.worldTurnMutator) var mutator
            return mutator.applyWorldTurn(WorldTurnOutcome(results: [result]), to: [house])
        }

        let updatedBot = updated[0].members[0]
        XCTAssertEqual(updatedBot.currentExp, 50)
        XCTAssertEqual(updatedBot.actionPoints.current, 60)
        XCTAssertEqual(updatedBot.inventory.materials.first?.quantity, 3)
    }
}

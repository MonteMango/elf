//
//  DefaultBotDecisionMakerTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import XCTest
@testable import elf_Kit

/// Tests for the hard-coded world-turn planner: spend the elf's whole AP budget
/// on hunting.
final class DefaultBotDecisionMakerTests: XCTestCase {

    private let sut = DefaultBotDecisionMaker()
    private let slot = RosterSlot(houseIndex: 1, memberIndex: 2, id: ElfID())

    func testPlanTurn_fullActionPoints_yieldsFiveHunts() {
        let elf = TestFixtures.elf(actionPoints: .unsafeCreate(current: 100, maximum: 100))

        let plan = sut.planTurn(for: elf, at: slot)

        XCTAssertEqual(plan.actions, Array(repeating: .hunt, count: 5))
        XCTAssertEqual(plan.totalCost, 100)
        XCTAssertEqual(plan.slot, slot)
    }

    func testPlanTurn_partialActionPoints_floorsToWholeHunts() {
        let elf = TestFixtures.elf(actionPoints: .unsafeCreate(current: 50, maximum: 100))

        let plan = sut.planTurn(for: elf, at: slot)

        // 50 / 20 = 2 hunts (the leftover 10 AP can't fund a third).
        XCTAssertEqual(plan.actions.count, 2)
        XCTAssertEqual(plan.totalCost, 40)
    }

    func testPlanTurn_zeroActionPoints_yieldsEmptyPlan() {
        let elf = TestFixtures.elf(actionPoints: .unsafeCreate(current: 0, maximum: 100))

        let plan = sut.planTurn(for: elf, at: slot)

        XCTAssertTrue(plan.actions.isEmpty)
        XCTAssertEqual(plan.totalCost, 0)
    }
}

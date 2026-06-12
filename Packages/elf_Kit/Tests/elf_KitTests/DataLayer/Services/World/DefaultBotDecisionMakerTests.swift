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

    func testPlanTurn_huntCountFloorsAcrossBudgets() {
        // (available AP, expected hunts) — 20 AP per hunt, integer floor.
        let cases: [(ap: Int, hunts: Int)] = [
            (0, 0), (19, 0), (20, 1), (40, 2), (99, 4), (100, 5)
        ]

        for testCase in cases {
            let elf = TestFixtures.elf(actionPoints: .unsafeCreate(current: testCase.ap, maximum: 100))

            let plan = sut.planTurn(for: elf, at: slot)

            XCTAssertEqual(plan.actions.count, testCase.hunts, "AP \(testCase.ap) → \(testCase.hunts) hunts")
            XCTAssertTrue(plan.actions.allSatisfy { $0 == .hunt })
        }
    }
}

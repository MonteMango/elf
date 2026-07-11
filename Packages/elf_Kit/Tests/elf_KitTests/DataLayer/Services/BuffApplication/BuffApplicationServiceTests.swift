//
//  BuffApplicationServiceTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// AC-06 (T9): `BuffApplicationService` is the sole domain-rule owner for
/// folding a new buff application into an existing applied-buff collection.
/// This suite covers both call paths that delegate to it:
/// - `GameSession.applyGlobalBuffToPlayer`/`applyGlobalBuff` -> `applyAsGlobal`
/// - `BattleFightViewModel.applyBattleBuff` -> `applyAsBattle`
final class BuffApplicationServiceTests: XCTestCase {

    private func makeBuff(
        id: BuffID,
        scope: BuffScope,
        stackingRule: BuffStackingRule
    ) -> Buff {
        Buff(
            id: id,
            title: "Test Buff",
            imageName: "test",
            description: "test",
            polarity: .positive,
            scope: scope,
            durationDays: 3,
            stackingRule: stackingRule,
            effects: []
        )
    }

    // MARK: - applyAsGlobal (GameSession call path)

    func testApplyAsGlobal_NewBuff_AppendsAppliedBuffWithCurrentDay() {
        let buffId = BuffID()
        let buff = makeBuff(id: buffId, scope: .global, stackingRule: .refresh)

        let result = withDependencies {
            $0.buffsRepository = ElfBuffsRepository(buffsData: BuffsData(version: "test", buffs: [buff]))
        } operation: {
            @Dependency(\.buffApplicationService) var service
            return service.applyAsGlobal(buffId: buffId, to: [], currentDay: 7)
        }

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.buffId, buffId)
        XCTAssertEqual(result.first?.appliedOnDay, 7)
    }

    func testApplyAsGlobal_RefreshStacking_UpdatesAppliedOnDayWithoutDuplicating() {
        let buffId = BuffID()
        let buff = makeBuff(id: buffId, scope: .global, stackingRule: .refresh)
        let existing = [AppliedBuff(buffId: buffId, appliedOnDay: 1)]

        let result = withDependencies {
            $0.buffsRepository = ElfBuffsRepository(buffsData: BuffsData(version: "test", buffs: [buff]))
        } operation: {
            @Dependency(\.buffApplicationService) var service
            return service.applyAsGlobal(buffId: buffId, to: existing, currentDay: 5)
        }

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.appliedOnDay, 5)
    }

    // MARK: - applyAsBattle (BattleFightViewModel call path)

    func testApplyAsBattle_NewBuff_AppendsAppliedBuffWithNilDay() {
        let buffId = BuffID()
        let buff = makeBuff(id: buffId, scope: .battle, stackingRule: .stack)

        let result = withDependencies {
            $0.buffsRepository = ElfBuffsRepository(buffsData: BuffsData(version: "test", buffs: [buff]))
        } operation: {
            @Dependency(\.buffApplicationService) var service
            return service.applyAsBattle(buffId: buffId, to: [])
        }

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.buffId, buffId)
        XCTAssertNil(result.first?.appliedOnDay)
    }

    func testApplyAsBattle_StackStacking_IncrementsStacksOnExistingEntry() {
        let buffId = BuffID()
        let buff = makeBuff(id: buffId, scope: .battle, stackingRule: .stack)
        let existing = [AppliedBuff(buffId: buffId, appliedOnDay: nil, stacks: 1)]

        let result = withDependencies {
            $0.buffsRepository = ElfBuffsRepository(buffsData: BuffsData(version: "test", buffs: [buff]))
        } operation: {
            @Dependency(\.buffApplicationService) var service
            return service.applyAsBattle(buffId: buffId, to: existing)
        }

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.stacks, 2)
    }

    /// Scope mismatch (buff registered `.global`, applied via `applyAsBattle`)
    /// triggers `assertionFailure` in DEBUG (crashes the test process) per
    /// `DefaultBuffApplicationService`'s documented contract — not exercised
    /// here since XCTest can't assert against a debug trap.
}

//
//  DefaultBuffEffectsCalculatorTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Pins down `DefaultBuffEffectsCalculator.apply(...)` math: how flat and
/// percent buff effects fold over `HeroAttributes`. Particular focus on the
/// selective-percent path (`combatAttributesPercentDelta`) added for the
/// Exhausted debuff — it must touch only the named attributes and leave the
/// rest untouched.
final class DefaultBuffEffectsCalculatorTests: XCTestCase {

    // MARK: - Helpers

    private func makeBase() -> HeroAttributes {
        HeroAttributes(
            hitPoints: 100, manaPoints: 50,
            agility: 10, strength: 10, power: 10, instinct: 10, endurance: 10
        )
    }

    /// Single-buff catalog wrapped in a `ElfBuffsRepository` for the
    /// `withDependencies` override. Title/polarity/scope don't matter for the
    /// math — only `effects` and `stackingRule` are consulted by the calculator.
    private func makeRepository(buffId: BuffID, effects: [BuffEffect], scope: BuffScope = .battle) -> ElfBuffsRepository {
        let buff = Buff(
            id: buffId,
            title: "Test",
            imageName: "",
            description: "",
            polarity: .negative,
            scope: scope,
            durationDays: nil,
            stackingRule: .ignore,
            effects: effects
        )
        return ElfBuffsRepository(buffsData: BuffsData(version: "1.0-test", buffs: [buff]))
    }

    private func makeRepository(buffs: [Buff]) -> ElfBuffsRepository {
        ElfBuffsRepository(buffsData: BuffsData(version: "1.0-test", buffs: buffs))
    }

    // MARK: - Tests

    func testApply_NoBuffs_ReturnsBaseUnchanged() {
        let calculator = withDependencies {
            $0.buffsRepository = makeRepository(buffId: BuffID(), effects: [])
        } operation: { DefaultBuffEffectsCalculator() }

        let result = calculator.apply(buffs: [], to: makeBase())
        XCTAssertEqual(result, makeBase())
    }

    func testApply_CombatAttributesPercent_ScalesAllFive() {
        let buffId = BuffID()
        let calculator = withDependencies {
            $0.buffsRepository = makeRepository(buffId: buffId, effects: [.combatAttributesPercent(-0.5)])
        } operation: { DefaultBuffEffectsCalculator() }

        let result = calculator.apply(buffs: [AppliedBuff(buffId: buffId)], to: makeBase())

        // All five combat attrs halved; HP/MP untouched.
        XCTAssertEqual(result.strength.value, 5)
        XCTAssertEqual(result.agility.value, 5)
        XCTAssertEqual(result.power.value, 5)
        XCTAssertEqual(result.instinct.value, 5)
        XCTAssertEqual(result.endurance.value, 5)
        XCTAssertEqual(result.hitPoints.value, 100)
        XCTAssertEqual(result.manaPoints.value, 50)
    }

    /// Exhausted is the motivating case: −30 % to Strength + Endurance,
    /// everything else MUST stay at the base value.
    func testApply_CombatAttributesPercentDelta_OnlyTouchesNamedAttributes() {
        let buffId = BuffID()
        let calculator = withDependencies {
            $0.buffsRepository = makeRepository(
                buffId: buffId,
                effects: [.combatAttributesPercentDelta(
                    CombatAttributesPercentDelta(strength: -0.30, endurance: -0.30)
                )]
            )
        } operation: { DefaultBuffEffectsCalculator() }

        let result = calculator.apply(buffs: [AppliedBuff(buffId: buffId)], to: makeBase())

        XCTAssertEqual(result.strength.value, 7,  "strength 10 × 0.70 = 7 (rounded down)")
        XCTAssertEqual(result.endurance.value, 7, "endurance 10 × 0.70 = 7")
        XCTAssertEqual(result.agility.value, 10,  "agility must NOT be touched")
        XCTAssertEqual(result.power.value, 10,    "power must NOT be touched")
        XCTAssertEqual(result.instinct.value, 10, "instinct must NOT be touched")
        XCTAssertEqual(result.hitPoints.value, 100)
        XCTAssertEqual(result.manaPoints.value, 50)
    }

    func testApply_PercentDelta_StacksMultiplyTheEffect() {
        // .ignore catalog → stacks would normally be 1, but the calculator
        // honors whatever `AppliedBuff.stacks` value the caller passed.
        // Verify the multiplier is applied per stack.
        let buffId = BuffID()
        let calculator = withDependencies {
            $0.buffsRepository = makeRepository(
                buffId: buffId,
                effects: [.combatAttributesPercentDelta(
                    CombatAttributesPercentDelta(strength: -0.20)
                )]
            )
        } operation: { DefaultBuffEffectsCalculator() }

        let result = calculator.apply(
            buffs: [AppliedBuff(buffId: buffId, stacks: 2)],
            to: makeBase()
        )

        // 2 stacks × −0.20 = −0.40 → strength 10 × 0.60 = 6.
        XCTAssertEqual(result.strength.value, 6)
        XCTAssertEqual(result.agility.value, 10)
    }

    func testApply_GlobalPercentAndPercentDelta_CombineAdditively() {
        // One buff: −0.20 to all (global percent).
        // Another buff: −0.10 selectively to strength.
        // Expected effective multiplier on strength = 1 − 0.20 − 0.10 = 0.70.
        // Effective multiplier on agility = 1 − 0.20 = 0.80.
        let globalId = BuffID()
        let selectiveId = BuffID()
        let buffs = [
            Buff(id: globalId, title: "G", imageName: "", description: "",
                 polarity: .negative, scope: .battle, durationDays: nil,
                 stackingRule: .ignore, effects: [.combatAttributesPercent(-0.20)]),
            Buff(id: selectiveId, title: "S", imageName: "", description: "",
                 polarity: .negative, scope: .battle, durationDays: nil,
                 stackingRule: .ignore, effects: [
                    .combatAttributesPercentDelta(CombatAttributesPercentDelta(strength: -0.10))
                 ])
        ]
        let calculator = withDependencies {
            $0.buffsRepository = makeRepository(buffs: buffs)
        } operation: { DefaultBuffEffectsCalculator() }

        let result = calculator.apply(
            buffs: [AppliedBuff(buffId: globalId), AppliedBuff(buffId: selectiveId)],
            to: makeBase()
        )

        XCTAssertEqual(result.strength.value, 7,  "10 × (1 − 0.20 − 0.10) = 7")
        XCTAssertEqual(result.agility.value, 8,   "10 × (1 − 0.20) = 8")
    }

    func testApply_OverdrivenPercent_ClampsAtZero() {
        let buffId = BuffID()
        let calculator = withDependencies {
            $0.buffsRepository = makeRepository(
                buffId: buffId,
                effects: [.combatAttributesPercentDelta(
                    CombatAttributesPercentDelta(strength: -2.0)
                )]
            )
        } operation: { DefaultBuffEffectsCalculator() }

        let result = calculator.apply(buffs: [AppliedBuff(buffId: buffId)], to: makeBase())

        XCTAssertEqual(result.strength.value, 0, "Multiplier clamps to 0; strength can't go negative")
    }
}

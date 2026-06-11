//
//  BattleLoopEndToEndTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// End-to-end battle-loop regression test that runs through the REAL combat
/// chain (`ElfBattleSimulationService` → `DefaultBattleRoundRunner` →
/// `ElfCombatRoundExecutor` → `ElfSnapshotCombatCalculator` → crit/dodge/
/// damage/endurance services), seeded for determinism. Unlike the
/// balance-sweep integration target (print-only, excluded from the default
/// test plan), this lives in the default unit plan and asserts invariants, so
/// the integration of the whole stack is regression-guarded on every run.
final class BattleLoopEndToEndTests: XCTestCase {

    /// Real services resolve via `.live`; buffs are passthrough (no game-data
    /// catalog in the unit target) and the RNG is seeded so the battle is
    /// reproducible.
    private func runBattle(seed: UInt64) async -> BattleResult {
        let attacker = makeHero(name: "Attacker", power: 40, strength: 30, endurance: 0, hp: 80, weapon: 12...16)
        let defender = makeHero(name: "Defender", power: 0, strength: 8, endurance: 24, hp: 60, weapon: 4...6)
        let battle = Battle(leftTeam: [attacker], rightTeam: [defender])

        return await withDependencies {
            $0.context = .live
            $0.buffEffectsCalculator = PassthroughBuffEffectsCalculator()
            // The combat chain pulls these at init even though a no-buff,
            // weapon-via-AttackProfile battle never reads them. Their live
            // values fatalError without app bootstrap, so stub them: an empty
            // item repo and empty buff catalog.
            $0.itemsRepository = FakeItemsRepository()
            $0.buffsRepository = ElfBuffsRepository(buffsData: BuffsData(version: "1.0-empty", buffs: []))
            $0.withRandomNumberGenerator = WithRandomNumberGenerator(
                SeededRandomNumberGenerator(seed: seed)
            )
        } operation: {
            await ElfBattleSimulationService().runSingleBattle(
                battle,
                using: WithRandomNumberGenerator(SeededRandomNumberGenerator(seed: seed))
            )
        }
    }

    private func makeHero(
        name: String, power: Int16, strength: Int16, endurance: Int16, hp: Int16,
        weapon: ClosedRange<Int>
    ) -> CombatantSnapshot {
        CombatantSnapshot(
            source: .synthetic,
            name: name,
            imageName: "",
            combatantType: .elf,
            level: 12,
            currentHP: Int(hp),
            currentMP: 0,
            currentEP: GameMechanicsConstants.startingEP,
            maxEP: GameMechanicsConstants.startingEP,
            baseHeroAttributes: HeroAttributes(
                hitPoints: Attribute(hp), manaPoints: 0,
                agility: 0, strength: Attribute(strength), power: Attribute(power),
                instinct: 4, endurance: Attribute(endurance)
            ),
            attacks: [AttackProfile(minimumAttack: Int(weapon.lowerBound), maximumAttack: Int(weapon.upperBound), epBlockCost: 300)],
            defensePoints: 2,
            armorValues: [:]
        )
    }

    // MARK: - Invariants

    func testFullBattle_TerminatesWithConsistentResult() async {
        let r = await runBattle(seed: 7)

        XCTAssertGreaterThanOrEqual(r.totalRounds, 1, "a battle must run at least one round")

        switch r.winner {
        case .left:
            XCTAssertLessThanOrEqual(r.bot2FinalHP, 0, "loser (right) must be dead")
            XCTAssertGreaterThan(r.bot1FinalHP, 0, "winner (left) must be alive")
        case .right:
            XCTAssertLessThanOrEqual(r.bot1FinalHP, 0, "loser (left) must be dead")
            XCTAssertGreaterThan(r.bot2FinalHP, 0, "winner (right) must be alive")
        case .draw:
            XCTFail("a decisive crit attacker vs a weaker defender should not draw")
        }

        // Statistics are populated and non-negative.
        XCTAssertGreaterThanOrEqual(r.statistics.bot1TotalDamage, 0)
        XCTAssertGreaterThanOrEqual(r.statistics.bot2TotalDamage, 0)
    }

    /// The determinism guarantee, asserted in the DEFAULT test plan (the
    /// integration target's equivalent is excluded from normal runs).
    func testFullBattle_SameSeedIsReproducible() async {
        let a = await runBattle(seed: 7)
        let b = await runBattle(seed: 7)
        XCTAssertEqual(a.winner, b.winner)
        XCTAssertEqual(a.totalRounds, b.totalRounds)
        XCTAssertEqual(a.bot1FinalHP, b.bot1FinalHP)
        XCTAssertEqual(a.bot2FinalHP, b.bot2FinalHP)
    }
}

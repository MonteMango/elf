//
//  ElfCombatRoundExecutorTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for `ElfCombatRoundExecutor` — the orchestration seam between the
/// per-strike calculator and the round runner. Verifies it cross-wires
/// attacker/defender correctly (a player's *taken* results come from the
/// **bot's** attack) and aggregates damage + EP from each side's results.
final class ElfCombatRoundExecutorTests: XCTestCase {

    // MARK: - Mocks

    /// Returns a distinct result dictionary per attacker name and records the
    /// (attack, defense, attacker, defender) tuple of every call so the test
    /// can assert the executor's cross-wiring.
    final class MockCalculator: SnapshotCombatCalculator, @unchecked Sendable {
        struct Call: Sendable {
            let attacking: Set<BodyPart>
            let defending: Set<BodyPart>
            let attackerName: String
            let defenderName: String
        }
        nonisolated(unsafe) var calls: [Call] = []
        nonisolated(unsafe) var resultsByAttackerName: [String: [BodyPart: PointStatus]] = [:]

        func calculatePointStatus(
            attackingPoints: Set<BodyPart>,
            defendingPoints: Set<BodyPart>,
            attacker: CombatantSnapshot,
            defender: CombatantSnapshot,
            using generator: WithRandomNumberGenerator
        ) -> [BodyPart: PointStatus] {
            calls.append(Call(
                attacking: attackingPoints, defending: defendingPoints,
                attackerName: attacker.name, defenderName: defender.name
            ))
            return resultsByAttackerName[attacker.name] ?? [:]
        }
    }

    /// `calculateTotalDamage` uses the real `PointStatus.damageTakenValue`
    /// formula so the test asserts genuine aggregation; the roll methods are
    /// unused stubs.
    final class StubDamageService: DamageService, @unchecked Sendable {
        func getRandomStrengthDamage(_ strengthAttribute: Int16, using generator: WithRandomNumberGenerator) -> Int16 { 0 }
        func getRandomDamageReduction(stat: Int16, coefficient: Double, using generator: WithRandomNumberGenerator) -> Int16 { 0 }
        func getWeaponDamage(weaponId: UUID?) -> (minDmg: Int16, maxDmg: Int16)? { nil }
        func calculateTotalDamage(from pointStatus: [BodyPart: PointStatus]) -> Int {
            pointStatus.values.reduce(0) { $0 + $1.damageTakenValue }
        }
    }

    // MARK: - Helpers

    private func snapshot(named name: String) -> CombatantSnapshot {
        CombatantSnapshot(
            id: UUID(),
            sourceId: UUID(),
            name: name,
            imageName: "",
            combatantType: .elf,
            currentHP: 100,
            currentMP: 0,
            currentEP: GameMechanicsConstants.startingEP,
            maxEP: GameMechanicsConstants.startingEP,
            baseHeroAttributes: HeroAttributes(
                hitPoints: 100, manaPoints: 0,
                agility: 10, strength: 10, power: 10, instinct: 10, endurance: 0
            ),
            attacks: [AttackProfile(minimumAttack: 1, maximumAttack: 5, epBlockCost: 200)],
            defensePoints: 2,
            armorValues: [:]
        )
    }

    private let seeded = WithRandomNumberGenerator(SeededRandomNumberGenerator(seed: 0xE1F))

    // MARK: - Tests

    func testExecuteRound_CrossWiresAttackerAndDefender() {
        let calc = MockCalculator()
        let player = snapshot(named: "Player")
        let bot = snapshot(named: "Bot")

        // Player's TAKEN results are produced when the bot attacks the player.
        calc.resultsByAttackerName["Bot"] = [
            .head: .hit(weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 3),
            .body: .blocked(epSpent: 200)
        ]
        // Bot's TAKEN results are produced when the player attacks the bot.
        calc.resultsByAttackerName["Player"] = [
            .legs: .critHit(weaponDamage: 8, strengthDamage: 2, enduranceReduction: 0, defenderArmor: 0, multiplier: 2.0, epSpent: 50)
        ]

        let result = withDependencies {
            $0.snapshotCombatCalculator = calc
            $0.damageService = StubDamageService()
        } operation: {
            ElfCombatRoundExecutor().executeRound(
                playerSnapshot: player,
                botSnapshot: bot,
                playerAttackPoints: [.legs],
                playerDefensePoints: [.head, .body],
                botAttackPoints: [.head, .body],
                botDefensePoints: [.legs],
                using: seeded
            )
        }

        // Wiring: player's results == what the calculator returned for the bot's attack.
        XCTAssertEqual(result.playerResults, calc.resultsByAttackerName["Bot"])
        XCTAssertEqual(result.botResults, calc.resultsByAttackerName["Player"])

        // The two calculator calls received the correct cross-wired arguments.
        XCTAssertEqual(calc.calls.count, 2)
        let playerCall = calc.calls.first { $0.attackerName == "Bot" }
        XCTAssertEqual(playerCall?.attacking, [.head, .body], "player results use the bot's attack points")
        XCTAssertEqual(playerCall?.defending, [.head, .body], "player results use the player's defense points")
        XCTAssertEqual(playerCall?.defenderName, "Player")
        let botCall = calc.calls.first { $0.attackerName == "Player" }
        XCTAssertEqual(botCall?.attacking, [.legs])
        XCTAssertEqual(botCall?.defending, [.legs])
        XCTAssertEqual(botCall?.defenderName, "Bot")
    }

    func testExecuteRound_AggregatesDamageAndEP() {
        let calc = MockCalculator()
        calc.resultsByAttackerName["Bot"] = [
            .head: .hit(weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 3), // 12 dmg, 0 EP
            .body: .blocked(epSpent: 200)                                                              // 0 dmg, 200 EP
        ]
        calc.resultsByAttackerName["Player"] = [
            .legs: .critHit(weaponDamage: 8, strengthDamage: 2, enduranceReduction: 0, defenderArmor: 0, multiplier: 2.0, epSpent: 50) // 18 dmg, 50 EP
        ]

        let result = withDependencies {
            $0.snapshotCombatCalculator = calc
            $0.damageService = StubDamageService()
        } operation: {
            ElfCombatRoundExecutor().executeRound(
                playerSnapshot: snapshot(named: "Player"),
                botSnapshot: snapshot(named: "Bot"),
                playerAttackPoints: [.legs],
                playerDefensePoints: [.head, .body],
                botAttackPoints: [.head, .body],
                botDefensePoints: [.legs],
                using: seeded
            )
        }

        XCTAssertEqual(result.playerDamageTaken, 12, "weapon 10 + str 5 − armor 3")
        XCTAssertEqual(result.botDamageTaken, 18, "weapon 8 × 2.0 crit + str 2")
        XCTAssertEqual(result.playerEPSpent, 200, "block cost from the player's defended body part")
        XCTAssertEqual(result.botEPSpent, 50, "EP spent on the bot's crit-pierced block")
    }
}

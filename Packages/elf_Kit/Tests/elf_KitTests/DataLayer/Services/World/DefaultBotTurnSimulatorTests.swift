//
//  DefaultBotTurnSimulatorTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Integration tests for the real `DefaultBotTurnSimulator` driving the live
/// combat stack, seeded for determinism. Only the bootstrap-only repositories
/// are stubbed (same recipe as `BattleLoopEndToEndTests`) plus a fixed monster
/// pool — so a bot hunt resolves through the genuine battle path.
@MainActor
final class DefaultBotTurnSimulatorTests: XCTestCase {

    // MARK: - Fakes

    private struct FixedMonsterRepository: MonsterRepository {
        let pool: [Monster]
        func getAll() -> [Monster] { pool }
        func getById(id: MonsterID) -> Monster? { pool.first { $0.id == id } }
        func getMonsters(world: WorldType, level: Int) -> [Monster] { pool }
    }

    // MARK: - Fixtures

    private func makeMonster() -> Monster {
        Monster(
            id: MonsterID(),
            title: "Test Monster",
            imageName: "",
            expReward: [ChanceAmount(amount: 50, chance: 1.0)],
            rightAttack: AttackProfile(minimumAttack: 1, maximumAttack: 3, epBlockCost: 100),
            leftAttack: nil,
            defensePoints: 2, hitPoints: 40, manaPoints: 0,
            strength: 5, agility: 5, power: 5, instinct: 5, endurance: 5,
            partsProtection: PartsProtection(head: 0, left: 0, center: 0, right: 0, legs: 0),
            drops: MonsterDrops(weapons: [], armor: [], materials: [])
        )
    }

    private func huntPlan(_ count: Int) -> BotTurnPlan {
        BotTurnPlan(
            slot: RosterSlot(houseIndex: 0, memberIndex: 1, id: ElfID()),
            actions: Array(repeating: .hunt, count: count)
        )
    }

    private func simulate(
        plan: BotTurnPlan,
        elf: ElfInfo,
        seed: UInt64,
        pool: [Monster]
    ) async -> BotTurnResult {
        await withDependencies {
            $0.context = .live
            // Bootstrap-only deps the combat chain pulls at init; stub them.
            $0.buffEffectsCalculator = PassthroughBuffEffectsCalculator()
            $0.itemsRepository = FakeItemsRepository()
            $0.buffsRepository = ElfBuffsRepository(buffsData: BuffsData(version: "1.0-empty", buffs: []))
            $0.withRandomNumberGenerator = WithRandomNumberGenerator(SeededRandomNumberGenerator(seed: 1))
            $0.monsterRepository = FixedMonsterRepository(pool: pool)
        } operation: {
            await DefaultBotTurnSimulator().simulate(plan, elf: elf, seed: seed)
        }
    }

    // MARK: - Tests

    func testSimulate_runsOneBattlePerHunt_andSpendsFullAP() async {
        let result = await simulate(plan: huntPlan(5), elf: TestFixtures.elf(), seed: 42, pool: [makeMonster()])

        XCTAssertEqual(result.battles.count, 5)
        XCTAssertEqual(result.actionPointsSpent, 100)
    }

    func testSimulate_isDeterministic_forSameSeed() async {
        // Same plan instance (so the slot id matches) + same monster + same seed.
        let plan = huntPlan(5)
        let elf = TestFixtures.elf()
        let pool = [makeMonster()]

        let first = await simulate(plan: plan, elf: elf, seed: 7, pool: pool)
        let second = await simulate(plan: plan, elf: elf, seed: 7, pool: pool)

        XCTAssertEqual(first, second)
    }

    func testSimulate_experienceComesOnlyFromWonBattles() async {
        let result = await simulate(plan: huntPlan(5), elf: TestFixtures.elf(), seed: 42, pool: [makeMonster()])

        // Each won battle grants the monster's 50 exp; losses/draws grant none.
        let wins = result.battles.filter(\.won).count
        XCTAssertEqual(result.experienceGained, wins * 50)
    }

    func testSimulate_emptyMonsterPool_yieldsEmptyResult() async {
        let result = await simulate(plan: huntPlan(5), elf: TestFixtures.elf(), seed: 42, pool: [])

        XCTAssertTrue(result.battles.isEmpty)
        XCTAssertEqual(result.actionPointsSpent, 0)
        XCTAssertEqual(result.experienceGained, 0)
    }

    func testSimulate_emptyPlan_yieldsEmptyResult() async {
        let result = await simulate(plan: huntPlan(0), elf: TestFixtures.elf(), seed: 42, pool: [makeMonster()])

        XCTAssertTrue(result.battles.isEmpty)
        XCTAssertEqual(result.actionPointsSpent, 0)
    }
}

//
//  DefaultBattleBuilderTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for `DefaultBattleBuilder` — the shared assembler that turns a resolved
/// party + monster list into a `Battle`. A lightweight `MockCombatantSnapshotBuilder`
/// isolates the builder's own logic (team assembly, equipment map, HP/MP
/// clamping, empty-team guards) from snapshot internals; the mock pins every elf
/// snapshot at `maxHP == 80` / `maxMP == 20` so clamp assertions are deterministic.
final class DefaultBattleBuilderTests: XCTestCase {

    // MARK: - Mocks

    /// Returns deterministic snapshots: elves cap at HP 80 / MP 20 (full reserves),
    /// monsters mirror their own HP. Each snapshot gets a fresh `CombatantID`.
    private final class MockCombatantSnapshotBuilder: CombatantSnapshotBuilder, @unchecked Sendable {
        func buildSnapshot(elf: ElfInfo, level: Int, globalBuffs: [AppliedBuff]) -> CombatantSnapshot {
            CombatantSnapshot(
                source: .elf(elf.id),
                name: elf.name,
                imageName: elf.imageName,
                combatantType: .elf,
                level: level,
                currentHP: 80,
                currentMP: 20,
                currentEP: 0,
                maxEP: 0,
                baseHeroAttributes: HeroAttributes(
                    hitPoints: 80, manaPoints: 20, agility: 0,
                    strength: 0, power: 0, instinct: 0, endurance: 0
                ),
                attacks: [],
                defensePoints: 2,
                armorValues: [:],
                globalBuffs: globalBuffs
            )
        }

        func buildSnapshot(
            name: String,
            imageName: String,
            level: Int,
            fightStyleAttributes: HeroAttributes,
            randomLevelAttributes: HeroAttributes,
            equipped: EquippedItems,
            globalBuffs: [AppliedBuff]
        ) -> CombatantSnapshot {
            CombatantSnapshot(
                source: .synthetic,
                name: name,
                imageName: imageName,
                combatantType: .elf,
                level: level,
                currentHP: 80,
                currentMP: 20,
                currentEP: 0,
                maxEP: 0,
                baseHeroAttributes: HeroAttributes(
                    hitPoints: 80, manaPoints: 20, agility: 0,
                    strength: 0, power: 0, instinct: 0, endurance: 0
                ),
                attacks: [],
                defensePoints: 2,
                armorValues: [:],
                globalBuffs: globalBuffs
            )
        }

        func buildSnapshot(from monster: Monster, globalBuffs: [AppliedBuff]) -> CombatantSnapshot {
            CombatantSnapshot(
                source: .monster(monster.id),
                name: monster.title,
                imageName: monster.imageName,
                combatantType: .monster,
                currentHP: monster.hitPoints,
                currentMP: monster.manaPoints,
                currentEP: 0,
                maxEP: 0,
                baseHeroAttributes: HeroAttributes(),
                attacks: [],
                defensePoints: monster.defensePoints,
                armorValues: [:],
                globalBuffs: globalBuffs
            )
        }
    }

    private final class MockProgressionService: ProgressionService, @unchecked Sendable {
        func calculateLevel(currentExp: Int) -> Int { max(1, min(12, currentExp / 100)) }
        func totalExp(forLevel level: Int) -> Int { max(1, min(12, level)) * 100 }
        func expToNextLevel(currentExp: Int) -> Int { 100 }
        func experienceTransition(previousExp: Int, gained: Int) -> ExperienceTransition {
            ExperienceTransition(
                previousLevel: 1, previousExp: previousExp, previousExpToNext: 100,
                newLevel: 1, newExp: previousExp + gained, newExpToNext: 100
            )
        }
        func expProgress(currentExp: Int) -> Double { 0 }
        func farmingLevel(exp: Int) -> Int { 0 }
        func farmingProgress(exp: Int) -> Double { 0 }
    }

    // MARK: - Properties

    private var builder: DefaultBattleBuilder!

    // MARK: - Setup

    /// Construct the SUT inside `withDependencies` so `DefaultBattleBuilder`'s
    /// init resolves the stubbed `snapshotBuilder` / `progressionService`.
    override func invokeTest() {
        withDependencies {
            $0.snapshotBuilder = MockCombatantSnapshotBuilder()
            $0.progressionService = MockProgressionService()
        } operation: {
            self.builder = DefaultBattleBuilder()
            super.invokeTest()
            self.builder = nil
        }
    }

    // MARK: - Fixtures

    private func makeMonster() -> Monster {
        Monster(
            id: MonsterID(),
            title: "Test Monster",
            imageName: "",
            expReward: [ChanceAmount(amount: 50, chance: 1.0)],
            rightAttack: AttackProfile(minimumAttack: 1, maximumAttack: 3, epBlockCost: 100),
            defensePoints: 2,
            hitPoints: 40,
            manaPoints: 0,
            strength: 5, agility: 5, power: 5, instinct: 5, endurance: 5,
            partsProtection: PartsProtection(head: 0, left: 0, center: 0, right: 0, legs: 0),
            drops: MonsterDrops(weapons: [], armor: [], materials: [])
        )
    }

    // MARK: - Empty-team guards

    func testBuildBattle_EmptyParty_ReturnsNil() {
        XCTAssertNil(builder.buildBattle(party: [], monsters: [makeMonster()]))
    }

    func testBuildBattle_EmptyMonsters_ReturnsNil() {
        let party = [BattlePartyMember(elf: TestFixtures.elf())]
        XCTAssertNil(builder.buildBattle(party: party, monsters: []))
    }

    // MARK: - Single combatant assembly

    func testBuildBattle_SingleMemberSingleMonster_AssemblesBothTeams() throws {
        let elf = TestFixtures.elf(name: "Hero")
        let battle = try XCTUnwrap(
            builder.buildBattle(party: [BattlePartyMember(elf: elf)], monsters: [makeMonster()])
        )

        XCTAssertEqual(battle.leftTeam.count, 1)
        XCTAssertEqual(battle.rightTeam.count, 1)
        XCTAssertEqual(battle.leftTeam[0].name, "Hero")
        XCTAssertEqual(battle.leftTeam[0].combatantType, .elf)
        XCTAssertEqual(battle.rightTeam[0].combatantType, .monster)
    }

    // MARK: - Equipment map

    func testBuildBattle_EquippedKeyedByEachMemberSnapshotId() {
        let party = [
            BattlePartyMember(elf: TestFixtures.elf(name: "Hero")),
            BattlePartyMember(elf: TestFixtures.elf(name: "Ally"))
        ]
        guard let battle = builder.buildBattle(party: party, monsters: [makeMonster()]) else {
            return XCTFail("Expected a battle")
        }

        XCTAssertEqual(battle.equippedByCombatantId.count, 2)
        for snapshot in battle.leftTeam {
            XCTAssertNotNil(
                battle.equippedByCombatantId[snapshot.id],
                "Each elf-side combatant must have an equipment entry keyed by its snapshot id"
            )
        }
        // Monsters carry no equipment entry.
        XCTAssertNil(battle.equippedByCombatantId[battle.rightTeam[0].id])
    }

    // MARK: - Vitals override / clamping

    func testBuildBattle_NilVitals_SeedsFullReserves() throws {
        let elf = TestFixtures.elf()
        let battle = try XCTUnwrap(
            builder.buildBattle(party: [BattlePartyMember(elf: elf)], monsters: [makeMonster()])
        )
        let hero = battle.leftTeam[0]
        XCTAssertEqual(hero.currentHP, hero.maxHP, "nil HP override → full reserves")
        XCTAssertEqual(hero.currentMP, hero.maxMP, "nil MP override → full reserves")
        XCTAssertEqual(hero.maxHP, 80)
        XCTAssertEqual(hero.maxMP, 20)
    }

    func testBuildBattle_VitalsOverride_ClampedToMax() throws {
        let elf = TestFixtures.elf()
        let battle = try XCTUnwrap(
            builder.buildBattle(
                party: [BattlePartyMember(elf: elf, currentHP: 1000, currentMP: 1000)],
                monsters: [makeMonster()]
            )
        )
        let hero = battle.leftTeam[0]
        XCTAssertEqual(hero.currentHP, 80, "HP override above max clamps to maxHP")
        XCTAssertEqual(hero.currentMP, 20, "MP override above max clamps to maxMP")
    }

    func testBuildBattle_VitalsOverride_BelowMaxPreserved() throws {
        let elf = TestFixtures.elf()
        let battle = try XCTUnwrap(
            builder.buildBattle(
                party: [BattlePartyMember(elf: elf, currentHP: 30, currentMP: 5)],
                monsters: [makeMonster()]
            )
        )
        let hero = battle.leftTeam[0]
        XCTAssertEqual(hero.currentHP, 30, "HP override below max is kept as-is")
        XCTAssertEqual(hero.currentMP, 5, "MP override below max is kept as-is")
    }

    // MARK: - Order & monster expansion

    func testBuildBattle_PreservesPartyOrder() throws {
        let party = [
            BattlePartyMember(elf: TestFixtures.elf(name: "Hero")),
            BattlePartyMember(elf: TestFixtures.elf(name: "Ally1")),
            BattlePartyMember(elf: TestFixtures.elf(name: "Ally2"))
        ]
        let battle = try XCTUnwrap(builder.buildBattle(party: party, monsters: [makeMonster()]))
        XCTAssertEqual(battle.leftTeam.map(\.name), ["Hero", "Ally1", "Ally2"])
    }

    func testBuildBattle_MaterializesOneSnapshotPerMonster() throws {
        let monsters = Array(repeating: makeMonster(), count: 3)
        let battle = try XCTUnwrap(
            builder.buildBattle(party: [BattlePartyMember(elf: TestFixtures.elf())], monsters: monsters)
        )
        XCTAssertEqual(battle.rightTeam.count, 3)
    }
}

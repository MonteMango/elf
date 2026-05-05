//
//  DefaultCombatantSnapshotBuilderTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.12.25.
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for DefaultCombatantSnapshotBuilder
///
/// The builder creates CombatantSnapshot from:
/// - Elf configuration (name, level, attributes, equipment)
/// - Monster data
final class DefaultCombatantSnapshotBuilderTests: XCTestCase {

    // MARK: - Mock Services

    final class MockItemsRepository: ItemsRepository, @unchecked Sendable {
        var itemsToReturn: [UUID: Item] = [:]
        var heroItems: HeroItems {
            HeroItems(
                version: "1.0.0-test",
                helmets: [],
                gloves: [],
                shoes: [],
                upperBodies: [],
                bottomBodies: [],
                robes: [],
                weapons: [],
                shields: [],
                rings: [],
                necklaces: [],
                earrings: []
            )
        }

        func getItems(for heroItemType: HeroItemType) -> [Item] { [] }
        func getHeroItem(_ itemId: UUID) -> Item? { itemsToReturn[itemId] }
        func armorSlot(for itemId: UUID) -> ArmorSlot? { nil }
    }

    final class MockArmorService: ArmorService, @unchecked Sendable {
        var armorToReturn: [BodyPart: Int16] = [:]

        func getAllItemsArmor(for itemIds: [UUID]) -> [BodyPart: Int16] { armorToReturn }
    }

    // MARK: - Properties

    private var mockItemsRepository: MockItemsRepository!
    private var mockArmorService: MockArmorService!
    private var builder: DefaultCombatantSnapshotBuilder!

    // MARK: - Setup

    /// Wrap every test in `withDependencies` so the `builder`'s @Dependency property
    /// wrappers resolve to the per-test mocks. Mocks are created here (before
    /// `super.invokeTest()`) because `setUp` would otherwise run after the
    /// `withDependencies` block opens and leave the closure reading `nil`.
    override func invokeTest() {
        let mockItems = MockItemsRepository()
        let mockArmor = MockArmorService()
        self.mockItemsRepository = mockItems
        self.mockArmorService = mockArmor

        withDependencies {
            $0.itemsRepository = mockItems
            $0.armorService = mockArmor
        } operation: {
            self.builder = DefaultCombatantSnapshotBuilder()
            super.invokeTest()
            self.builder = nil
            self.mockItemsRepository = nil
            self.mockArmorService = nil
        }
    }

    // MARK: - Monster Snapshot Tests

    func testBuildSnapshot_FromMonster_SetsCorrectValues() {
        // Given
        let monster = Monster(
            id: UUID(),
            title: "Goblin",
            imageName: "monster_goblin",
            expReward: [ChanceAmount(amount: 10, chance: 1.0)],
            minimumAttack: 5,
            maximumAttack: 10,
            attackPoints: 1,
            defensePoints: 2,
            hitPoints: 100,
            manaPoints: 0,
            strength: 15,
            agility: 12,
            power: 8,
            intuition: 10,
            endurance: 0,
            partsProtection: PartsProtection(head: 2, left: 1, center: 3, right: 1, legs: 2),
            drops: MonsterDrops(weapons: [], armor: [], materials: [])
        )

        // When
        let snapshot = builder.buildSnapshot(from: monster)

        // Then
        XCTAssertEqual(snapshot.name, "Goblin")
        XCTAssertEqual(snapshot.imageName, "monster_goblin")
        XCTAssertEqual(snapshot.combatantType, .monster)
        XCTAssertEqual(snapshot.level, 1)
        XCTAssertEqual(snapshot.currentHP, 100)
        XCTAssertEqual(snapshot.maxHP, 100)
        XCTAssertEqual(snapshot.strength, 15)
        XCTAssertEqual(snapshot.agility, 12)
        XCTAssertEqual(snapshot.power, 8)
        XCTAssertEqual(snapshot.intuition, 10)
        XCTAssertEqual(snapshot.attackPoints, 1)
        XCTAssertEqual(snapshot.defensePoints, 2)
        XCTAssertEqual(snapshot.minimumAttack, 5)
        XCTAssertEqual(snapshot.maximumAttack, 10)
    }

    func testBuildSnapshot_FromMonster_MapsArmorCorrectly() {
        // Given
        let monster = Monster(
            id: UUID(),
            title: "Test",
            imageName: "",
            expReward: [],
            minimumAttack: 0,
            maximumAttack: 0,
            attackPoints: 1,
            defensePoints: 2,
            hitPoints: 50,
            manaPoints: 0,
            strength: 10,
            agility: 10,
            power: 10,
            intuition: 10,
            endurance: 0,
            partsProtection: PartsProtection(head: 5, left: 3, center: 10, right: 3, legs: 7),
            drops: MonsterDrops(weapons: [], armor: [], materials: [])
        )

        // When
        let snapshot = builder.buildSnapshot(from: monster)

        // Then
        XCTAssertEqual(snapshot.armorValues[.head], 5)
        XCTAssertEqual(snapshot.armorValues[.leftHand], 3)
        XCTAssertEqual(snapshot.armorValues[.body], 10)
        XCTAssertEqual(snapshot.armorValues[.rightHand], 3)
        XCTAssertEqual(snapshot.armorValues[.legs], 7)
    }

    func testBuildSnapshot_FromMonster_HasNoEquipment() {
        // Given
        let monster = Monster(
            id: UUID(),
            title: "Test",
            imageName: "",
            expReward: [],
            minimumAttack: 0,
            maximumAttack: 0,
            attackPoints: 1,
            defensePoints: 2,
            hitPoints: 50,
            manaPoints: 0,
            strength: 10,
            agility: 10,
            power: 10,
            intuition: 10,
            endurance: 0,
            partsProtection: PartsProtection(head: 0, left: 0, center: 0, right: 0, legs: 0),
            drops: MonsterDrops(weapons: [], armor: [], materials: [])
        )

        // When
        let snapshot = builder.buildSnapshot(from: monster)

        // Then
        XCTAssertNil(snapshot.helmetItem)
        XCTAssertNil(snapshot.glovesItem)
        XCTAssertNil(snapshot.shoesItem)
        XCTAssertNil(snapshot.upperBodyItem)
        XCTAssertNil(snapshot.bottomBodyItem)
        XCTAssertNil(snapshot.robeItem)
        XCTAssertNil(snapshot.leftWeaponItem)
        XCTAssertNil(snapshot.rightWeaponItem)
        XCTAssertNil(snapshot.shieldItem)
        XCTAssertNil(snapshot.ringItem)
        XCTAssertNil(snapshot.necklaceItem)
        XCTAssertNil(snapshot.earringsItem)
        XCTAssertFalse(snapshot.hasEquipment)
    }

    func testBuildSnapshot_FromMonster_PreservesSourceId() {
        // Given
        let monsterId = UUID()
        let monster = Monster(
            id: monsterId,
            title: "Test",
            imageName: "",
            expReward: [],
            minimumAttack: 0,
            maximumAttack: 0,
            attackPoints: 1,
            defensePoints: 2,
            hitPoints: 50,
            manaPoints: 0,
            strength: 10,
            agility: 10,
            power: 10,
            intuition: 10,
            endurance: 0,
            partsProtection: PartsProtection(head: 0, left: 0, center: 0, right: 0, legs: 0),
            drops: MonsterDrops(weapons: [], armor: [], materials: [])
        )

        // When
        let snapshot = builder.buildSnapshot(from: monster)

        // Then
        XCTAssertEqual(snapshot.sourceId, monsterId)
    }

    // MARK: - Elf Snapshot Tests

    func testBuildSnapshot_FromElfConfig_SetsBasicValues() async {
        // Given
        let fightStyleAttributes = HeroAttributes(
            hitPoints: 100,
            manaPoints: 50,
            agility: 10,
            strength: 15,
            power: 12,
            instinct: 8,
            endurance: 0
        )
        let randomLevelAttributes = HeroAttributes(
            hitPoints: 20,
            manaPoints: 10,
            agility: 2,
            strength: 3,
            power: 2,
            instinct: 1,
            endurance: 0
        )

        // When
        let snapshot = await builder.buildSnapshot(
            name: "Test Elf",
            imageName: "elf_test",
            level: 5,
            fightStyleAttributes: fightStyleAttributes,
            randomLevelAttributes: randomLevelAttributes,
            selectedItems: [:]
        )

        // Then
        XCTAssertNotNil(snapshot)
        XCTAssertEqual(snapshot?.name, "Test Elf")
        XCTAssertEqual(snapshot?.imageName, "elf_test")
        XCTAssertEqual(snapshot?.combatantType, .elf)
        XCTAssertEqual(snapshot?.level, 5)
    }

    func testBuildSnapshot_FromElfConfig_AggregatesAttributes() async {
        // Given
        let fightStyleAttributes = HeroAttributes(
            hitPoints: 100,
            manaPoints: 50,
            agility: 10,
            strength: 15,
            power: 12,
            instinct: 8,
            endurance: 4
        )
        let randomLevelAttributes = HeroAttributes(
            hitPoints: 20,
            manaPoints: 10,
            agility: 5,
            strength: 5,
            power: 3,
            instinct: 2,
            endurance: 2
        )

        // When
        let snapshot = await builder.buildSnapshot(
            name: "Test",
            imageName: "",
            level: 1,
            fightStyleAttributes: fightStyleAttributes,
            randomLevelAttributes: randomLevelAttributes,
            selectedItems: [:]
        )

        // Then
        XCTAssertNotNil(snapshot)
        XCTAssertEqual(snapshot?.currentHP, 120) // 100 + 20
        XCTAssertEqual(snapshot?.maxHP, 120)
        XCTAssertEqual(snapshot?.strength, 20)   // 15 + 5
        XCTAssertEqual(snapshot?.agility, 15)    // 10 + 5
        XCTAssertEqual(snapshot?.power, 15)      // 12 + 3
        XCTAssertEqual(snapshot?.intuition, 10)  // 8 + 2 (instinct)
        XCTAssertEqual(snapshot?.endurance, 6)   // 4 + 2
    }

    func testBuildSnapshot_FromElfConfig_NoWeapons_HasDefaultAttackDefensePoints() async {
        // Given
        let attributes = HeroAttributes(
            hitPoints: 100, manaPoints: 0, agility: 0, strength: 0, power: 0, instinct: 0, endurance: 0
        )

        // When
        let snapshot = await builder.buildSnapshot(
            name: "Test",
            imageName: "",
            level: 1,
            fightStyleAttributes: attributes,
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [:]
        )

        // Then
        XCTAssertNotNil(snapshot)
        XCTAssertEqual(snapshot?.attackPoints, 1)  // Default
        XCTAssertEqual(snapshot?.defensePoints, 2) // Default (no shield)
    }

    func testBuildSnapshot_FromElfConfig_UsesArmorFromService() async {
        // Given
        let attributes = HeroAttributes(
            hitPoints: 100, manaPoints: 0, agility: 0, strength: 0, power: 0, instinct: 0, endurance: 0
        )
        mockArmorService.armorToReturn = [
            .head: 5,
            .body: 10,
            .leftHand: 3,
            .rightHand: 3,
            .legs: 7
        ]

        // When
        let snapshot = await builder.buildSnapshot(
            name: "Test",
            imageName: "",
            level: 1,
            fightStyleAttributes: attributes,
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [:]
        )

        // Then
        XCTAssertNotNil(snapshot)
        XCTAssertEqual(snapshot?.armorValues[.head], 5)
        XCTAssertEqual(snapshot?.armorValues[.body], 10)
        XCTAssertEqual(snapshot?.armorValues[.leftHand], 3)
        XCTAssertEqual(snapshot?.armorValues[.rightHand], 3)
        XCTAssertEqual(snapshot?.armorValues[.legs], 7)
    }
}

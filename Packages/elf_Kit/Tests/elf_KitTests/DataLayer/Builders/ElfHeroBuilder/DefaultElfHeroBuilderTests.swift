//
//  DefaultElfHeroBuilderTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import XCTest
@testable import elf_Kit

/// Tests for DefaultElfHeroBuilder
///
/// Builder creates ElfHero from:
/// - Level and attributes
/// - Selected items (by UUID)
/// - Weapon placement logic (right hand, dual wield, two-handed)
/// - Armor calculation via ArmorService
final class DefaultElfHeroBuilderTests: XCTestCase {

    // MARK: - Mock Services

    /// Mock ItemsRepository with configurable item storage
    final class MockItemsRepository: ItemsRepository, @unchecked Sendable {
        nonisolated(unsafe) var itemStorage: [UUID: Item] = [:]

        var heroItems: HeroItems {
            return HeroItems(
                version: "1.0",
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

        func getHeroItem(_ id: UUID) -> Item? {
            return itemStorage[id]
        }

        func getItems(for type: HeroItemType) -> [Item] {
            return []
        }

        func addItem(_ item: Item) {
            itemStorage[item.id] = item
        }
    }

    /// Mock ArmorService with configurable return values
    final class MockArmorService: ArmorService, @unchecked Sendable {
        nonisolated(unsafe) var armorToReturn: [BodyPart: Int16] = [:]

        func getAllItemsArmor(for itemIds: [UUID]) async -> [BodyPart: Int16] {
            return armorToReturn
        }
    }

    // MARK: - Test Helpers

    private var mockItemsRepository: MockItemsRepository!
    private var mockArmorService: MockArmorService!

    private func makeBuilder() -> DefaultElfHeroBuilder {
        return DefaultElfHeroBuilder(
            itemsRepository: mockItemsRepository,
            armorService: mockArmorService
        )
    }

    private func makeAttributes() -> HeroAttributes {
        return HeroAttributes(
            hitPoints: 100,
            manaPoints: 50,
            agility: 15,
            strength: 20,
            power: 10,
            instinct: 10
        )
    }

    private func makePrimaryWeapon(id: UUID = UUID()) -> WeaponItem {
        let json = """
        {
            "id": "\(id.uuidString)",
            "title": "Test Sword",
            "tier": 1,
            "minimumAttackPoint": 5,
            "maximumAttackPoint": 10,
            "handUse": "primary"
        }
        """
        return try! JSONDecoder().decode(WeaponItem.self, from: Data(json.utf8))
    }

    private func makeSecondaryWeapon(id: UUID = UUID()) -> WeaponItem {
        let json = """
        {
            "id": "\(id.uuidString)",
            "title": "Test Dagger",
            "tier": 1,
            "minimumAttackPoint": 3,
            "maximumAttackPoint": 6,
            "handUse": "secondary"
        }
        """
        return try! JSONDecoder().decode(WeaponItem.self, from: Data(json.utf8))
    }

    private func makeTwoHandedWeapon(id: UUID = UUID()) -> WeaponItem {
        let json = """
        {
            "id": "\(id.uuidString)",
            "title": "Test Greatsword",
            "tier": 2,
            "minimumAttackPoint": 10,
            "maximumAttackPoint": 20,
            "handUse": "both"
        }
        """
        return try! JSONDecoder().decode(WeaponItem.self, from: Data(json.utf8))
    }

    private func makeShield(id: UUID = UUID()) -> ShieldItem {
        let json = """
        {
            "id": "\(id.uuidString)",
            "title": "Test Shield",
            "tier": 1,
            "physicalDefensePoint": 5
        }
        """
        return try! JSONDecoder().decode(ShieldItem.self, from: Data(json.utf8))
    }

    override func setUp() {
        super.setUp()
        mockItemsRepository = MockItemsRepository()
        mockArmorService = MockArmorService()
    }

    override func tearDown() {
        mockItemsRepository = nil
        mockArmorService = nil
        super.tearDown()
    }

    // MARK: - Basic Build Tests

    func testBuildElfHero_WithNoItems_ReturnsHeroWithAttributes() async {
        // Given
        let builder = makeBuilder()
        let fightStyleAttrs = makeAttributes()
        let randomAttrs = HeroAttributes()

        // When
        let hero = await builder.buildElfHero(
            level: 5,
            fightStyleAttributes: fightStyleAttrs,
            randomLevelAttributes: randomAttrs,
            selectedItems: [:]
        )

        // Then
        XCTAssertNotNil(hero)
        XCTAssertEqual(hero?.level, 5)
        XCTAssertEqual(hero?.fightStyleAttributes.hitPoints, 100)
        XCTAssertEqual(hero?.fightStyleAttributes.strength, 20)
        XCTAssertNil(hero?.rightHandWeaponElfItem)
        XCTAssertNil(hero?.leftHandWeaponElfItem)
        XCTAssertNil(hero?.shieldElfItem)
    }

    func testBuildElfHero_PassesThroughLevel() async {
        // Given
        let builder = makeBuilder()

        // Test various levels
        for level: Int16 in [1, 10, 50, 100] {
            // When
            let hero = await builder.buildElfHero(
                level: level,
                fightStyleAttributes: makeAttributes(),
                randomLevelAttributes: HeroAttributes(),
                selectedItems: [:]
            )

            // Then
            XCTAssertEqual(hero?.level, Int(level))
        }
    }

    // MARK: - Weapon Placement Tests

    func testBuildElfHero_WithPrimaryWeapon_PlacesInRightHand() async {
        // Given
        let builder = makeBuilder()
        let weaponId = UUID()
        let weapon = makePrimaryWeapon(id: weaponId)
        mockItemsRepository.addItem(weapon)

        // When
        let hero = await builder.buildElfHero(
            level: 1,
            fightStyleAttributes: makeAttributes(),
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [.weapons: weaponId]
        )

        // Then
        XCTAssertNotNil(hero?.rightHandWeaponElfItem)
        XCTAssertEqual(hero?.rightHandWeaponElfItem?.id, weaponId)
        XCTAssertNil(hero?.leftHandWeaponElfItem)
    }

    func testBuildElfHero_WithTwoHandedWeapon_PlacesInRightHandOnly() async {
        // Given
        let builder = makeBuilder()
        let weaponId = UUID()
        let weapon = makeTwoHandedWeapon(id: weaponId)
        mockItemsRepository.addItem(weapon)

        // When
        let hero = await builder.buildElfHero(
            level: 1,
            fightStyleAttributes: makeAttributes(),
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [.weapons: weaponId]
        )

        // Then
        XCTAssertNotNil(hero?.rightHandWeaponElfItem)
        XCTAssertEqual(hero?.rightHandWeaponElfItem?.id, weaponId)
        XCTAssertNil(hero?.leftHandWeaponElfItem)
        XCTAssertNil(hero?.shieldElfItem) // Two-handed prevents shield
    }

    func testBuildElfHero_WithTwoHandedWeaponAndShield_IgnoresShield() async {
        // Given
        let builder = makeBuilder()
        let weaponId = UUID()
        let shieldId = UUID()
        let weapon = makeTwoHandedWeapon(id: weaponId)
        let shield = makeShield(id: shieldId)
        mockItemsRepository.addItem(weapon)
        mockItemsRepository.addItem(shield)

        // When
        let hero = await builder.buildElfHero(
            level: 1,
            fightStyleAttributes: makeAttributes(),
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [.weapons: weaponId, .shields: shieldId]
        )

        // Then
        XCTAssertNotNil(hero?.rightHandWeaponElfItem)
        XCTAssertNil(hero?.shieldElfItem) // Two-handed weapon ignores shield
    }

    func testBuildElfHero_WithWeaponAndShield_PlacesBothCorrectly() async {
        // Given
        let builder = makeBuilder()
        let weaponId = UUID()
        let shieldId = UUID()
        let weapon = makePrimaryWeapon(id: weaponId)
        let shield = makeShield(id: shieldId)
        mockItemsRepository.addItem(weapon)
        mockItemsRepository.addItem(shield)

        // When
        let hero = await builder.buildElfHero(
            level: 1,
            fightStyleAttributes: makeAttributes(),
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [.weapons: weaponId, .shields: shieldId]
        )

        // Then
        XCTAssertNotNil(hero?.rightHandWeaponElfItem)
        XCTAssertEqual(hero?.rightHandWeaponElfItem?.id, weaponId)
        XCTAssertNotNil(hero?.shieldElfItem)
        XCTAssertEqual(hero?.shieldElfItem?.id, shieldId)
        XCTAssertNil(hero?.leftHandWeaponElfItem)
    }

    func testBuildElfHero_DualWield_PlacesWeaponsInBothHands() async {
        // Given
        let builder = makeBuilder()
        let rightWeaponId = UUID()
        let leftWeaponId = UUID()
        let rightWeapon = makePrimaryWeapon(id: rightWeaponId)
        let leftWeapon = makeSecondaryWeapon(id: leftWeaponId)
        mockItemsRepository.addItem(rightWeapon)
        mockItemsRepository.addItem(leftWeapon)

        // When: Second weapon in shield slot = dual wield
        let hero = await builder.buildElfHero(
            level: 1,
            fightStyleAttributes: makeAttributes(),
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [.weapons: rightWeaponId, .shields: leftWeaponId]
        )

        // Then
        XCTAssertNotNil(hero?.rightHandWeaponElfItem)
        XCTAssertEqual(hero?.rightHandWeaponElfItem?.id, rightWeaponId)
        XCTAssertNotNil(hero?.leftHandWeaponElfItem)
        XCTAssertEqual(hero?.leftHandWeaponElfItem?.id, leftWeaponId)
        XCTAssertNil(hero?.shieldElfItem) // No shield when dual wielding
    }

    // MARK: - Shield Only Tests

    func testBuildElfHero_WithShieldOnly_PlacesShieldCorrectly() async {
        // Given
        let builder = makeBuilder()
        let shieldId = UUID()
        let shield = makeShield(id: shieldId)
        mockItemsRepository.addItem(shield)

        // When: No primary weapon, just shield
        let hero = await builder.buildElfHero(
            level: 1,
            fightStyleAttributes: makeAttributes(),
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [.shields: shieldId]
        )

        // Then
        XCTAssertNil(hero?.rightHandWeaponElfItem)
        XCTAssertNil(hero?.leftHandWeaponElfItem)
        XCTAssertNotNil(hero?.shieldElfItem)
        XCTAssertEqual(hero?.shieldElfItem?.id, shieldId)
    }

    // MARK: - Armor Service Tests

    func testBuildElfHero_AppliesArmorValues() async {
        // Given
        let builder = makeBuilder()
        mockArmorService.armorToReturn = [
            .head: 10,
            .body: 15,
            .legs: 8
        ]

        // When
        let hero = await builder.buildElfHero(
            level: 1,
            fightStyleAttributes: makeAttributes(),
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [:]
        )

        // Then
        XCTAssertEqual(hero?.armorValues[.head], 10)
        XCTAssertEqual(hero?.armorValues[.body], 15)
        XCTAssertEqual(hero?.armorValues[.legs], 8)
    }

    // MARK: - Nil Item ID Tests

    func testBuildElfHero_WithNilItemIds_HandlesGracefully() async {
        // Given
        let builder = makeBuilder()

        // When: Pass nil values explicitly
        let hero = await builder.buildElfHero(
            level: 1,
            fightStyleAttributes: makeAttributes(),
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [
                .helmet: nil,
                .weapons: nil,
                .shields: nil
            ]
        )

        // Then
        XCTAssertNotNil(hero)
        XCTAssertNil(hero?.rightHandWeaponElfItem)
        XCTAssertNil(hero?.shieldElfItem)
    }

    func testBuildElfHero_WithNonExistentItemId_ReturnsNilForThatItem() async {
        // Given
        let builder = makeBuilder()
        let nonExistentId = UUID()
        // Don't add item to repository

        // When
        let hero = await builder.buildElfHero(
            level: 1,
            fightStyleAttributes: makeAttributes(),
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [.weapons: nonExistentId]
        )

        // Then
        XCTAssertNotNil(hero)
        XCTAssertNil(hero?.rightHandWeaponElfItem) // Item not found
    }

    // MARK: - Attack and Defense Points Tests

    func testBuildElfHero_SingleWeapon_HasOneAttackPoint() async {
        // Given
        let builder = makeBuilder()
        let weaponId = UUID()
        let weapon = makePrimaryWeapon(id: weaponId)
        mockItemsRepository.addItem(weapon)

        // When
        let hero = await builder.buildElfHero(
            level: 1,
            fightStyleAttributes: makeAttributes(),
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [.weapons: weaponId]
        )

        // Then
        XCTAssertEqual(hero?.atackPointsAmount, 1)
        XCTAssertEqual(hero?.defensePointsAmount, 2) // No shield = 2
    }

    func testBuildElfHero_WithShield_HasThreeDefensePoints() async {
        // Given
        let builder = makeBuilder()
        let weaponId = UUID()
        let shieldId = UUID()
        let weapon = makePrimaryWeapon(id: weaponId)
        let shield = makeShield(id: shieldId)
        mockItemsRepository.addItem(weapon)
        mockItemsRepository.addItem(shield)

        // When
        let hero = await builder.buildElfHero(
            level: 1,
            fightStyleAttributes: makeAttributes(),
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [.weapons: weaponId, .shields: shieldId]
        )

        // Then
        XCTAssertEqual(hero?.atackPointsAmount, 1)
        XCTAssertEqual(hero?.defensePointsAmount, 3) // With shield = 3
    }

    func testBuildElfHero_DualWield_HasTwoAttackPoints() async {
        // Given
        let builder = makeBuilder()
        let rightWeaponId = UUID()
        let leftWeaponId = UUID()
        let rightWeapon = makePrimaryWeapon(id: rightWeaponId)
        let leftWeapon = makeSecondaryWeapon(id: leftWeaponId)
        mockItemsRepository.addItem(rightWeapon)
        mockItemsRepository.addItem(leftWeapon)

        // When
        let hero = await builder.buildElfHero(
            level: 1,
            fightStyleAttributes: makeAttributes(),
            randomLevelAttributes: HeroAttributes(),
            selectedItems: [.weapons: rightWeaponId, .shields: leftWeaponId]
        )

        // Then
        XCTAssertEqual(hero?.atackPointsAmount, 2) // Dual wield = 2
        XCTAssertEqual(hero?.defensePointsAmount, 2) // No shield = 2
    }
}

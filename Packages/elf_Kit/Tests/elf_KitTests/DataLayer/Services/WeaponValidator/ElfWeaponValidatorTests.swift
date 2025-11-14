//
//  ElfWeaponValidatorTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import Combine
import XCTest
@testable import elf_Kit

final class ElfWeaponValidatorTests: XCTestCase {

    // MARK: - Test Helpers

    /// Creates a test WeaponItem using JSON decoding
    private func makeWeaponItem(
        id: UUID = UUID(),
        title: String = "Test Weapon",
        tier: Int16 = 1,
        handUse: WeaponHandUse,
        minimumAttackPoint: Int16 = 1,
        maximumAttackPoint: Int16 = 5
    ) throws -> WeaponItem {
        let json: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "tier": tier,
            "minimumAttackPoint": minimumAttackPoint,
            "maximumAttackPoint": maximumAttackPoint,
            "handUse": handUse.rawValue
        ]

        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        return try decoder.decode(WeaponItem.self, from: data)
    }

    /// Creates a test ShieldItem using JSON decoding
    private func makeShieldItem(
        id: UUID = UUID(),
        title: String = "Test Shield",
        tier: Int16 = 1,
        physicalDefensePoint: Int16 = 10
    ) throws -> ShieldItem {
        let json: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "tier": tier,
            "physicalDefensePoint": physicalDefensePoint
        ]

        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        return try decoder.decode(ShieldItem.self, from: data)
    }

    // MARK: - Fake Repository

    final class FakeItemsRepository: ItemsRepository {
        var items: [UUID: Item] = [:]

        var heroItems: HeroItems? = nil
        var heroItemsPublisher: AnyPublisher<HeroItems?, Never> {
            Just(heroItems).eraseToAnyPublisher()
        }

        func loadHeroItems() async throws { }

        func getHeroItem(_ id: UUID) async -> Item? {
            return items[id]
        }
    }

    // MARK: - Category A: Basic Operations

    func testUnequipWeaponClearsSlot() async throws {
        // given
        let weaponId = UUID()
        let weapon = try makeWeaponItem(id: weaponId, title: "Sword", handUse: .primary)

        let repository = FakeItemsRepository()
        repository.items[weaponId] = weapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: weaponId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: nil,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertNil(result[.weapons] ?? nil, "Selecting nil should clear weapons slot")
    }

    func testUnequipShieldClearsSlot() async throws {
        // given
        let shieldId = UUID()
        let shield = try makeShieldItem(id: shieldId, title: "Shield")

        let repository = FakeItemsRepository()
        repository.items[shieldId] = shield

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: shieldId
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: nil,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertNil(result[.shields] ?? nil, "Selecting nil should clear shields slot")
    }

    func testInvalidItemIdReturnsCurrentState() async throws {
        // given
        let invalidId = UUID()
        let repository = FakeItemsRepository()
        // Don't add item to repository

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: invalidId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, currentItems[.weapons] ?? nil, "Invalid item ID should return unchanged state")
        XCTAssertEqual(result[.shields] ?? nil, currentItems[.shields] ?? nil, "Invalid item ID should return unchanged state")
    }

    // MARK: - Category B: Two-Handed Weapons

    func testTwoHandedWeaponClearsShield() async throws {
        // given
        let twoHandedId = UUID()
        let shieldId = UUID()

        let twoHandedWeapon = try makeWeaponItem(
            id: twoHandedId,
            title: "Great Sword",
            handUse: .both
        )
        let shield = try makeShieldItem(id: shieldId, title: "Shield")

        let repository = FakeItemsRepository()
        repository.items[twoHandedId] = twoHandedWeapon
        repository.items[shieldId] = shield

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: shieldId
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: twoHandedId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, twoHandedId, "Two-handed weapon should be equipped")
        XCTAssertNil(result[.shields] ?? nil, "Two-handed weapon should clear shields slot")
    }

    func testTwoHandedWeaponClearsSecondaryWeapon() async throws {
        // given
        let twoHandedId = UUID()
        let secondaryId = UUID()

        let twoHandedWeapon = try makeWeaponItem(
            id: twoHandedId,
            title: "Great Axe",
            handUse: .both
        )
        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Dagger",
            handUse: .secondary
        )

        let repository = FakeItemsRepository()
        repository.items[twoHandedId] = twoHandedWeapon
        repository.items[secondaryId] = secondaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: secondaryId
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: twoHandedId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, twoHandedId, "Two-handed weapon should be equipped")
        XCTAssertNil(result[.shields] ?? nil, "Two-handed weapon should clear secondary weapon in shields slot")
    }

    func testTwoHandedWeaponWithEmptyShields() async throws {
        // given
        let twoHandedId = UUID()
        let twoHandedWeapon = try makeWeaponItem(
            id: twoHandedId,
            title: "Great Hammer",
            handUse: .both
        )

        let repository = FakeItemsRepository()
        repository.items[twoHandedId] = twoHandedWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: twoHandedId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, twoHandedId, "Two-handed weapon should be equipped")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain empty")
    }

    func testTwoHandedWeaponWithEmptySlots() async throws {
        // given
        let twoHandedId = UUID()
        let twoHandedWeapon = try makeWeaponItem(
            id: twoHandedId,
            title: "Spear",
            handUse: .both
        )

        let repository = FakeItemsRepository()
        repository.items[twoHandedId] = twoHandedWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [:]

        // when
        let result = await validator.validateAndResolve(
            selecting: twoHandedId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, twoHandedId, "Two-handed weapon should be equipped")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain empty")
    }

    func testTwoHandedWeaponReplacesExistingTwoHanded() async throws {
        // given
        let firstTwoHandedId = UUID()
        let secondTwoHandedId = UUID()

        let firstTwoHanded = try makeWeaponItem(
            id: firstTwoHandedId,
            title: "Great Sword",
            handUse: .both
        )
        let secondTwoHanded = try makeWeaponItem(
            id: secondTwoHandedId,
            title: "Great Axe",
            handUse: .both
        )

        let repository = FakeItemsRepository()
        repository.items[firstTwoHandedId] = firstTwoHanded
        repository.items[secondTwoHandedId] = secondTwoHanded

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: firstTwoHandedId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: secondTwoHandedId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, secondTwoHandedId, "New two-handed weapon should replace old one")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain empty")
    }

    func testTwoHandedWeaponReplacesExistingPrimary() async throws {
        // given
        let primaryId = UUID()
        let twoHandedId = UUID()

        let primaryWeapon = try makeWeaponItem(
            id: primaryId,
            title: "Sword",
            handUse: .primary
        )
        let twoHandedWeapon = try makeWeaponItem(
            id: twoHandedId,
            title: "Great Sword",
            handUse: .both
        )

        let repository = FakeItemsRepository()
        repository.items[primaryId] = primaryWeapon
        repository.items[twoHandedId] = twoHandedWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: primaryId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: twoHandedId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, twoHandedId, "Two-handed weapon should replace primary weapon")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain empty")
    }

    // MARK: - Category C: Primary Weapons

    func testPrimaryWeaponWithShield() async throws {
        // given
        let primaryId = UUID()
        let shieldId = UUID()

        let primaryWeapon = try makeWeaponItem(
            id: primaryId,
            title: "Sword",
            handUse: .primary
        )
        let shield = try makeShieldItem(id: shieldId, title: "Shield")

        let repository = FakeItemsRepository()
        repository.items[primaryId] = primaryWeapon
        repository.items[shieldId] = shield

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: shieldId
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: primaryId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, primaryId, "Primary weapon should be equipped")
        XCTAssertEqual(result[.shields] ?? nil, shieldId, "Shield should be kept with primary weapon")
    }

    func testPrimaryWeaponClearsSecondaryInShields() async throws {
        // given
        let primaryId = UUID()
        let secondaryId = UUID()

        let primaryWeapon = try makeWeaponItem(
            id: primaryId,
            title: "Mace",
            handUse: .primary
        )
        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Dagger",
            handUse: .secondary
        )

        let repository = FakeItemsRepository()
        repository.items[primaryId] = primaryWeapon
        repository.items[secondaryId] = secondaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: secondaryId
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: primaryId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, primaryId, "Primary weapon should be equipped")
        XCTAssertNil(result[.shields] ?? nil, "Secondary weapon in shields should be cleared")
    }

    func testPrimaryWeaponWithEmptyShields() async throws {
        // given
        let primaryId = UUID()
        let primaryWeapon = try makeWeaponItem(
            id: primaryId,
            title: "Axe",
            handUse: .primary
        )

        let repository = FakeItemsRepository()
        repository.items[primaryId] = primaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: primaryId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, primaryId, "Primary weapon should be equipped")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain empty")
    }

    func testPrimaryWeaponWithEmptySlots() async throws {
        // given
        let primaryId = UUID()
        let primaryWeapon = try makeWeaponItem(
            id: primaryId,
            title: "Club",
            handUse: .primary
        )

        let repository = FakeItemsRepository()
        repository.items[primaryId] = primaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [:]

        // when
        let result = await validator.validateAndResolve(
            selecting: primaryId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, primaryId, "Primary weapon should be equipped")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain empty")
    }

    func testPrimaryWeaponReplacesExistingPrimary() async throws {
        // given
        let firstPrimaryId = UUID()
        let secondPrimaryId = UUID()

        let firstPrimary = try makeWeaponItem(
            id: firstPrimaryId,
            title: "Sword",
            handUse: .primary
        )
        let secondPrimary = try makeWeaponItem(
            id: secondPrimaryId,
            title: "Axe",
            handUse: .primary
        )

        let repository = FakeItemsRepository()
        repository.items[firstPrimaryId] = firstPrimary
        repository.items[secondPrimaryId] = secondPrimary

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: firstPrimaryId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: secondPrimaryId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, secondPrimaryId, "New primary weapon should replace old one")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain empty")
    }

    func testPrimaryWeaponReplacesExistingTwoHanded() async throws {
        // given
        let twoHandedId = UUID()
        let primaryId = UUID()

        let twoHandedWeapon = try makeWeaponItem(
            id: twoHandedId,
            title: "Great Sword",
            handUse: .both
        )
        let primaryWeapon = try makeWeaponItem(
            id: primaryId,
            title: "Sword",
            handUse: .primary
        )

        let repository = FakeItemsRepository()
        repository.items[twoHandedId] = twoHandedWeapon
        repository.items[primaryId] = primaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: twoHandedId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: primaryId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, primaryId, "Primary weapon should replace two-handed weapon")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain empty")
    }

    func testPrimaryWeaponReplacesExistingSecondary() async throws {
        // given
        let secondaryId = UUID()
        let primaryId = UUID()

        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Dagger",
            handUse: .secondary
        )
        let primaryWeapon = try makeWeaponItem(
            id: primaryId,
            title: "Sword",
            handUse: .primary
        )

        let repository = FakeItemsRepository()
        repository.items[secondaryId] = secondaryWeapon
        repository.items[primaryId] = primaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: secondaryId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: primaryId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, primaryId, "Primary weapon should replace secondary weapon")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain empty")
    }

    // MARK: - Category D: Secondary Weapons in Weapons Slot

    func testSecondaryWeaponWithShield() async throws {
        // given
        let secondaryId = UUID()
        let shieldId = UUID()

        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Dagger",
            handUse: .secondary
        )
        let shield = try makeShieldItem(id: shieldId, title: "Shield")

        let repository = FakeItemsRepository()
        repository.items[secondaryId] = secondaryWeapon
        repository.items[shieldId] = shield

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: shieldId
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: secondaryId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, secondaryId, "Secondary weapon should be equipped")
        XCTAssertEqual(result[.shields] ?? nil, shieldId, "Shield should be kept with secondary weapon")
    }

    func testSecondaryWeaponDualWield() async throws {
        // given
        let firstSecondaryId = UUID()
        let secondSecondaryId = UUID()

        let firstSecondary = try makeWeaponItem(
            id: firstSecondaryId,
            title: "Dagger 1",
            handUse: .secondary
        )
        let secondSecondary = try makeWeaponItem(
            id: secondSecondaryId,
            title: "Dagger 2",
            handUse: .secondary
        )

        let repository = FakeItemsRepository()
        repository.items[firstSecondaryId] = firstSecondary
        repository.items[secondSecondaryId] = secondSecondary

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: secondSecondaryId
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: firstSecondaryId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, firstSecondaryId, "Secondary weapon should be equipped")
        XCTAssertEqual(result[.shields] ?? nil, secondSecondaryId, "Second secondary weapon should be kept for dual-wield")
    }

    func testSecondaryWeaponWithEmptyShields() async throws {
        // given
        let secondaryId = UUID()
        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Short Sword",
            handUse: .secondary
        )

        let repository = FakeItemsRepository()
        repository.items[secondaryId] = secondaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: secondaryId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, secondaryId, "Secondary weapon should be equipped")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain empty")
    }

    func testSecondaryWeaponWithEmptySlots() async throws {
        // given
        let secondaryId = UUID()
        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Knife",
            handUse: .secondary
        )

        let repository = FakeItemsRepository()
        repository.items[secondaryId] = secondaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [:]

        // when
        let result = await validator.validateAndResolve(
            selecting: secondaryId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, secondaryId, "Secondary weapon should be equipped")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain empty")
    }

    func testSecondaryWeaponReplacesExistingPrimary() async throws {
        // given
        let primaryId = UUID()
        let secondaryId = UUID()

        let primaryWeapon = try makeWeaponItem(
            id: primaryId,
            title: "Sword",
            handUse: .primary
        )
        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Dagger",
            handUse: .secondary
        )

        let repository = FakeItemsRepository()
        repository.items[primaryId] = primaryWeapon
        repository.items[secondaryId] = secondaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: primaryId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: secondaryId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, secondaryId, "Secondary weapon should replace primary weapon")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain empty")
    }

    func testSecondaryWeaponReplacesExistingTwoHanded() async throws {
        // given
        let twoHandedId = UUID()
        let secondaryId = UUID()

        let twoHandedWeapon = try makeWeaponItem(
            id: twoHandedId,
            title: "Great Sword",
            handUse: .both
        )
        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Dagger",
            handUse: .secondary
        )

        let repository = FakeItemsRepository()
        repository.items[twoHandedId] = twoHandedWeapon
        repository.items[secondaryId] = secondaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: twoHandedId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: secondaryId,
            for: .weapons,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, secondaryId, "Secondary weapon should replace two-handed weapon")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain empty")
    }

    // MARK: - Category E: Shield Selection

    func testShieldWithPrimaryWeapon() async throws {
        // given
        let primaryId = UUID()
        let shieldId = UUID()

        let primaryWeapon = try makeWeaponItem(
            id: primaryId,
            title: "Sword",
            handUse: .primary
        )
        let shield = try makeShieldItem(id: shieldId, title: "Shield")

        let repository = FakeItemsRepository()
        repository.items[primaryId] = primaryWeapon
        repository.items[shieldId] = shield

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: primaryId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: shieldId,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, primaryId, "Primary weapon should be kept")
        XCTAssertEqual(result[.shields] ?? nil, shieldId, "Shield should be equipped")
    }

    func testShieldWithSecondaryWeapon() async throws {
        // given
        let secondaryId = UUID()
        let shieldId = UUID()

        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Dagger",
            handUse: .secondary
        )
        let shield = try makeShieldItem(id: shieldId, title: "Shield")

        let repository = FakeItemsRepository()
        repository.items[secondaryId] = secondaryWeapon
        repository.items[shieldId] = shield

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: secondaryId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: shieldId,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, secondaryId, "Secondary weapon should be kept")
        XCTAssertEqual(result[.shields] ?? nil, shieldId, "Shield should be equipped")
    }

    func testShieldClearsTwoHandedWeapon() async throws {
        // given
        let twoHandedId = UUID()
        let shieldId = UUID()

        let twoHandedWeapon = try makeWeaponItem(
            id: twoHandedId,
            title: "Great Sword",
            handUse: .both
        )
        let shield = try makeShieldItem(id: shieldId, title: "Shield")

        let repository = FakeItemsRepository()
        repository.items[twoHandedId] = twoHandedWeapon
        repository.items[shieldId] = shield

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: twoHandedId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: shieldId,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertNil(result[.weapons] ?? nil, "Two-handed weapon should be cleared")
        XCTAssertEqual(result[.shields] ?? nil, shieldId, "Shield should be equipped")
    }

    func testShieldWithEmptyWeapons() async throws {
        // given
        let shieldId = UUID()
        let shield = try makeShieldItem(id: shieldId, title: "Shield")

        let repository = FakeItemsRepository()
        repository.items[shieldId] = shield

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: shieldId,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertNil(result[.weapons] ?? nil, "Weapons slot should remain empty")
        XCTAssertEqual(result[.shields] ?? nil, shieldId, "Shield should be equipped")
    }

    func testShieldReplacesExistingShield() async throws {
        // given
        let firstShieldId = UUID()
        let secondShieldId = UUID()

        let firstShield = try makeShieldItem(id: firstShieldId, title: "Wooden Shield")
        let secondShield = try makeShieldItem(id: secondShieldId, title: "Iron Shield")

        let repository = FakeItemsRepository()
        repository.items[firstShieldId] = firstShield
        repository.items[secondShieldId] = secondShield

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: firstShieldId
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: secondShieldId,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertNil(result[.weapons] ?? nil, "Weapons slot should remain empty")
        XCTAssertEqual(result[.shields] ?? nil, secondShieldId, "New shield should replace old shield")
    }

    func testShieldReplacesSecondaryWeapon() async throws {
        // given
        let secondaryId = UUID()
        let shieldId = UUID()

        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Dagger",
            handUse: .secondary
        )
        let shield = try makeShieldItem(id: shieldId, title: "Shield")

        let repository = FakeItemsRepository()
        repository.items[secondaryId] = secondaryWeapon
        repository.items[shieldId] = shield

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: secondaryId
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: shieldId,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertNil(result[.weapons] ?? nil, "Weapons slot should remain empty")
        XCTAssertEqual(result[.shields] ?? nil, shieldId, "Shield should replace secondary weapon in shields slot")
    }

    // MARK: - Category F: Secondary Weapon in Shields Slot (Dual-Wield)

    func testSecondaryInShieldsWithSecondaryInWeapons() async throws {
        // given
        let weaponSecondaryId = UUID()
        let shieldSecondaryId = UUID()

        let weaponSecondary = try makeWeaponItem(
            id: weaponSecondaryId,
            title: "Dagger 1",
            handUse: .secondary
        )
        let shieldSecondary = try makeWeaponItem(
            id: shieldSecondaryId,
            title: "Dagger 2",
            handUse: .secondary
        )

        let repository = FakeItemsRepository()
        repository.items[weaponSecondaryId] = weaponSecondary
        repository.items[shieldSecondaryId] = shieldSecondary

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: weaponSecondaryId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: shieldSecondaryId,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.weapons] ?? nil, weaponSecondaryId, "Main secondary weapon should be kept")
        XCTAssertEqual(result[.shields] ?? nil, shieldSecondaryId, "Second secondary weapon should be equipped for dual-wield")
    }

    func testSecondaryInShieldsClearsPrimaryWeapon() async throws {
        // given
        let primaryId = UUID()
        let secondaryId = UUID()

        let primaryWeapon = try makeWeaponItem(
            id: primaryId,
            title: "Sword",
            handUse: .primary
        )
        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Dagger",
            handUse: .secondary
        )

        let repository = FakeItemsRepository()
        repository.items[primaryId] = primaryWeapon
        repository.items[secondaryId] = secondaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: primaryId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: secondaryId,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertNil(result[.weapons] ?? nil, "Primary weapon should be cleared for dual-wield")
        XCTAssertEqual(result[.shields] ?? nil, secondaryId, "Secondary weapon should be equipped in shields slot")
    }

    func testSecondaryInShieldsClearsTwoHandedWeapon() async throws {
        // given
        let twoHandedId = UUID()
        let secondaryId = UUID()

        let twoHandedWeapon = try makeWeaponItem(
            id: twoHandedId,
            title: "Great Sword",
            handUse: .both
        )
        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Dagger",
            handUse: .secondary
        )

        let repository = FakeItemsRepository()
        repository.items[twoHandedId] = twoHandedWeapon
        repository.items[secondaryId] = secondaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: twoHandedId,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: secondaryId,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertNil(result[.weapons] ?? nil, "Two-handed weapon should be cleared for dual-wield")
        XCTAssertEqual(result[.shields] ?? nil, secondaryId, "Secondary weapon should be equipped in shields slot")
    }

    func testSecondaryInShieldsWithEmptyWeapons() async throws {
        // given
        let secondaryId = UUID()
        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Dagger",
            handUse: .secondary
        )

        let repository = FakeItemsRepository()
        repository.items[secondaryId] = secondaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: secondaryId,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertNil(result[.weapons] ?? nil, "Weapons slot should remain empty")
        XCTAssertEqual(result[.shields] ?? nil, secondaryId, "Secondary weapon should be equipped in shields slot")
    }

    func testPrimaryInShieldsClearsBothSlots() async throws {
        // given
        let primaryId = UUID()
        let primaryWeapon = try makeWeaponItem(
            id: primaryId,
            title: "Sword",
            handUse: .primary
        )

        let repository = FakeItemsRepository()
        repository.items[primaryId] = primaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: primaryId,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertNil(result[.weapons] ?? nil, "Weapons slot should be cleared (invalid state)")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should be cleared (primary weapon cannot go there)")
    }

    func testTwoHandedInShieldsClearsBothSlots() async throws {
        // given
        let twoHandedId = UUID()
        let twoHandedWeapon = try makeWeaponItem(
            id: twoHandedId,
            title: "Great Sword",
            handUse: .both
        )

        let repository = FakeItemsRepository()
        repository.items[twoHandedId] = twoHandedWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: twoHandedId,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertNil(result[.weapons] ?? nil, "Weapons slot should be cleared (invalid state)")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should be cleared (two-handed weapon cannot go there)")
    }

    func testSecondaryInShieldsReplacesExistingShield() async throws {
        // given
        let shieldId = UUID()
        let secondaryId = UUID()

        let shield = try makeShieldItem(id: shieldId, title: "Shield")
        let secondaryWeapon = try makeWeaponItem(
            id: secondaryId,
            title: "Dagger",
            handUse: .secondary
        )

        let repository = FakeItemsRepository()
        repository.items[shieldId] = shield
        repository.items[secondaryId] = secondaryWeapon

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: shieldId
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: secondaryId,
            for: .shields,
            currentItems: currentItems
        )

        // then
        XCTAssertNil(result[.weapons] ?? nil, "Weapons slot should remain empty")
        XCTAssertEqual(result[.shields] ?? nil, secondaryId, "Secondary weapon should replace shield")
    }

    // MARK: - Category G: Edge Cases

    func testOtherSlotsPassThrough() async throws {
        // given
        let helmetId = UUID()
        let repository = FakeItemsRepository()
        // Not adding item to repository for this pass-through test

        let validator = ElfWeaponValidator(itemsRepository: repository)
        let currentItems: [HeroItemType: UUID?] = [
            .weapons: nil,
            .shields: nil
        ]

        // when
        let result = await validator.validateAndResolve(
            selecting: helmetId,
            for: .helmet,
            currentItems: currentItems
        )

        // then
        XCTAssertEqual(result[.helmet] ?? nil, helmetId, "Other slots should pass through without validation")
        XCTAssertNil(result[.weapons] ?? nil, "Weapons slot should remain unchanged")
        XCTAssertNil(result[.shields] ?? nil, "Shields slot should remain unchanged")
    }
}

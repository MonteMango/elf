//
//  ElfDamageServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.07.25.
//

import XCTest
@testable import elf_Kit

final class ElfDamageServiceTests: XCTestCase {

    // MARK: - Mocks

    /// Fake strategy for predictable behavior
    struct FakeStrategy: StrengthDamageDistributionStrategy {
        let distributionToReturn: DamageDistribution

        func distribution(for strength: Int16) -> DamageDistribution {
            return distributionToReturn
        }
    }

    /// Fake items repository
    final class FakeItemsRepository: ItemsRepository, @unchecked Sendable {
        nonisolated(unsafe) var items: [UUID: Item] = [:]

        var heroItems: HeroItems {
            return HeroItems(
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

        func getHeroItem(_ id: UUID) -> Item? {
            return items[id]
        }

        func getItems(for type: HeroItemType) -> [Item] {
            return []
        }
    }

    // MARK: - Test Helpers

    private func makeWeapon(id: UUID, minDamage: Int16, maxDamage: Int16) -> WeaponItem {
        let json = """
        {
            "id": "\(id.uuidString)",
            "title": "Test Weapon",
            "tier": 1,
            "minimumAttackPoint": \(minDamage),
            "maximumAttackPoint": \(maxDamage),
            "handUse": "primary"
        }
        """
        return try! JSONDecoder().decode(WeaponItem.self, from: Data(json.utf8))
    }

    // MARK: - Strength Damage Tests

    func testGetRandomStrengthDamage_ReturnsValueInRange() async {
        // Given
        let distribution = DamageDistribution(values: [5, 6, 7], weights: [1, 1, 1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        let service = ElfDamageService(
            itemsRepository: repository,
            distributionStrategy: strategy
        )

        // When: Run multiple times
        for _ in 0..<50 {
            let damage = service.getRandomStrengthDamage(10)

            // Then
            XCTAssertTrue((5...7).contains(damage), "Damage \(damage) should be in range 5-7")
        }
    }

    func testGetRandomStrengthDamage_EmptyDistribution_ReturnsZero() async {
        // Given
        let distribution = DamageDistribution(values: [], weights: [])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        let service = ElfDamageService(
            itemsRepository: repository,
            distributionStrategy: strategy
        )

        // When
        let damage = service.getRandomStrengthDamage(10)

        // Then
        XCTAssertEqual(damage, 0)
    }

    // MARK: - Weapon Damage Tests

    func testGetWeaponDamage_WithValidWeapon_ReturnsCorrectRange() async {
        // Given
        let weaponId = UUID()
        let weapon = makeWeapon(id: weaponId, minDamage: 10, maxDamage: 20)
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        repository.items[weaponId] = weapon

        let service = ElfDamageService(
            itemsRepository: repository,
            distributionStrategy: strategy
        )

        // When
        let result = service.getWeaponDamage(weaponId: weaponId)

        // Then
        XCTAssertEqual(result?.minDmg, 10)
        XCTAssertEqual(result?.maxDmg, 20)
    }

    func testGetWeaponDamage_WithNilWeaponId_ReturnsZero() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        let service = ElfDamageService(
            itemsRepository: repository,
            distributionStrategy: strategy
        )

        // When
        let result = service.getWeaponDamage(weaponId: nil)

        // Then
        XCTAssertEqual(result?.minDmg, 0)
        XCTAssertEqual(result?.maxDmg, 0)
    }

    func testGetWeaponDamage_WithNonExistentWeapon_ReturnsZero() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        let service = ElfDamageService(
            itemsRepository: repository,
            distributionStrategy: strategy
        )

        // When
        let result = service.getWeaponDamage(weaponId: UUID())

        // Then
        XCTAssertEqual(result?.minDmg, 0)
        XCTAssertEqual(result?.maxDmg, 0)
    }

    // MARK: - Calculate Total Damage Tests

    func testCalculateTotalDamage_Hit_AppliesArmorReduction() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        let service = ElfDamageService(
            itemsRepository: repository,
            distributionStrategy: strategy
        )

        // Weapon=10, Strength=5, Armor=3 -> 12
        let pointStatus: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 10, strengthDamage: 5, defenderArmor: 3)
        ]

        // When
        let totalDamage = service.calculateTotalDamage(from: pointStatus)

        // Then
        XCTAssertEqual(totalDamage, 12)
    }

    func testCalculateTotalDamage_Hit_MinimumZeroDamage() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        let service = ElfDamageService(
            itemsRepository: repository,
            distributionStrategy: strategy
        )

        // Weapon=5, Strength=3, Armor=20 -> max(0, 5+3-20) = 0
        let pointStatus: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 5, strengthDamage: 3, defenderArmor: 20)
        ]

        // When
        let totalDamage = service.calculateTotalDamage(from: pointStatus)

        // Then
        XCTAssertEqual(totalDamage, 0)
    }

    func testCalculateTotalDamage_CritHit_AppliesMultiplier() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        let service = ElfDamageService(
            itemsRepository: repository,
            distributionStrategy: strategy
        )

        // Base=10+5=15, Multiplier=2.0 -> 30, Armor=5 -> 25
        let pointStatus: [BodyPart: PointStatus] = [
            .body: .critHit(weaponDamage: 10, strengthDamage: 5, defenderArmor: 5, multiplier: 2.0)
        ]

        // When
        let totalDamage = service.calculateTotalDamage(from: pointStatus)

        // Then
        XCTAssertEqual(totalDamage, 25)
    }

    func testCalculateTotalDamage_Blocked_NoDamage() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        let service = ElfDamageService(
            itemsRepository: repository,
            distributionStrategy: strategy
        )

        let pointStatus: [BodyPart: PointStatus] = [
            .head: .blocked(wasCrit: false)
        ]

        // When
        let totalDamage = service.calculateTotalDamage(from: pointStatus)

        // Then
        XCTAssertEqual(totalDamage, 0)
    }

    func testCalculateTotalDamage_Dodged_NoDamage() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        let service = ElfDamageService(
            itemsRepository: repository,
            distributionStrategy: strategy
        )

        let pointStatus: [BodyPart: PointStatus] = [
            .body: .dodged(wasCrit: true)
        ]

        // When
        let totalDamage = service.calculateTotalDamage(from: pointStatus)

        // Then
        XCTAssertEqual(totalDamage, 0)
    }

    func testCalculateTotalDamage_Multiple_SumsCorrectly() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        let service = ElfDamageService(
            itemsRepository: repository,
            distributionStrategy: strategy
        )

        // Head: 10+5-3=12, Body: 20+10-5=25, Legs: blocked=0
        let pointStatus: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 10, strengthDamage: 5, defenderArmor: 3),
            .body: .hit(weaponDamage: 20, strengthDamage: 10, defenderArmor: 5),
            .legs: .blocked(wasCrit: false)
        ]

        // When
        let totalDamage = service.calculateTotalDamage(from: pointStatus)

        // Then
        XCTAssertEqual(totalDamage, 37)
    }
}

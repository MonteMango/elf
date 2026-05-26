//
//  ElfDamageServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.07.25.
//

import Dependencies
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

    /// Fake endurance reduction strategy. Defaults to a zero-reduction
    /// single-value distribution so existing strength/weapon/armor tests stay
    /// untouched; tests that exercise endurance reduction override it.
    struct FakeEnduranceStrategy: EnduranceDamageReductionDistributionStrategy {
        var distributionToReturn: DamageDistribution = DamageDistribution(values: [0], weights: [1])

        func distribution(for endurance: Int16) -> DamageDistribution {
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

        func armorSlot(for itemId: UUID) -> ArmorSlot? { nil }
    }

    // MARK: - Test Helpers

    private func makeWeapon(id: UUID, minDamage: Int16, maxDamage: Int16) -> WeaponItem {
        // swiftlint:disable:next force_try
        return try! TestFixtures.weaponItem(
            id: id, handUse: .oneHand,
            minimumAttackPoint: minDamage,
            maximumAttackPoint: maxDamage,
            epBlockCost: 200
        )
    }

    // MARK: - Strength Damage Tests

    func testGetRandomStrengthDamage_ReturnsValueInRange() async {
        // Given
        let distribution = DamageDistribution(values: [5, 6, 7], weights: [1, 1, 1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()

            // When: Run multiple times
            for _ in 0..<50 {
                let damage = service.getRandomStrengthDamage(10)

                // Then
                XCTAssertTrue((5...7).contains(damage), "Damage \(damage) should be in range 5-7")
            }
        }
    }

    func testGetRandomStrengthDamage_EmptyDistribution_ReturnsZero() async {
        // Given
        let distribution = DamageDistribution(values: [], weights: [])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        let damage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()

            // When
            return service.getRandomStrengthDamage(10)
        }

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

        let result = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()

            // When
            return service.getWeaponDamage(weaponId: weaponId)
        }

        // Then
        XCTAssertEqual(result?.minDmg, 10)
        XCTAssertEqual(result?.maxDmg, 20)
    }

    func testGetWeaponDamage_WithNilWeaponId_ReturnsZero() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        let result = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()

            // When
            return service.getWeaponDamage(weaponId: nil)
        }

        // Then
        XCTAssertEqual(result?.minDmg, 0)
        XCTAssertEqual(result?.maxDmg, 0)
    }

    func testGetWeaponDamage_WithNonExistentWeapon_ReturnsZero() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        let result = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()

            // When
            return service.getWeaponDamage(weaponId: UUID())
        }

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

        // Weapon=10, Strength=5, EndRed=0, Armor=3 -> 12
        let pointStatus: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 3)
        ]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()

            // When
            return service.calculateTotalDamage(from: pointStatus)
        }

        // Then
        XCTAssertEqual(totalDamage, 12)
    }

    func testCalculateTotalDamage_Hit_MinimumZeroDamage() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        // Weapon=5, Strength=3, EndRed=0, Armor=20 -> max(0, 5+3-20) = 0
        let pointStatus: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 5, strengthDamage: 3, enduranceReduction: 0, defenderArmor: 20)
        ]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()

            // When
            return service.calculateTotalDamage(from: pointStatus)
        }

        // Then
        XCTAssertEqual(totalDamage, 0)
    }

    func testCalculateTotalDamage_CritHit_AppliesMultiplier() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        // Only weapon scales: weapon=10 * 2.0 = 20, + strength 5 = 25,
        // - endurance 0 = 25, - armor 5 = 20.
        let pointStatus: [BodyPart: PointStatus] = [
            .body: .critHit(weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 5, multiplier: 2.0, epSpent: 0)
        ]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()

            // When
            return service.calculateTotalDamage(from: pointStatus)
        }

        // Then
        XCTAssertEqual(totalDamage, 20)
    }

    func testCalculateTotalDamage_Blocked_NoDamage() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        let pointStatus: [BodyPart: PointStatus] = [
            .head: .blocked(wasCrit: false, epSpent: 0)
        ]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()

            // When
            return service.calculateTotalDamage(from: pointStatus)
        }

        // Then
        XCTAssertEqual(totalDamage, 0)
    }

    func testCalculateTotalDamage_Dodged_NoDamage() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        let pointStatus: [BodyPart: PointStatus] = [
            .body: .dodged(wasCrit: true)
        ]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()

            // When
            return service.calculateTotalDamage(from: pointStatus)
        }

        // Then
        XCTAssertEqual(totalDamage, 0)
    }

    func testCalculateTotalDamage_Multiple_SumsCorrectly() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        // Head: 10+5-0-3=12, Body: 20+10-0-5=25, Legs: blocked=0
        let pointStatus: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 3),
            .body: .hit(weaponDamage: 20, strengthDamage: 10, enduranceReduction: 0, defenderArmor: 5),
            .legs: .blocked(wasCrit: false, epSpent: 0)
        ]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()

            // When
            return service.calculateTotalDamage(from: pointStatus)
        }

        // Then
        XCTAssertEqual(totalDamage, 37)
    }

    // MARK: - Endurance Damage Reduction Tests

    func testGetRandomEnduranceDamageReduction_ReturnsValueInRange() async {
        // Given
        let strengthStrategy = FakeStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let enduranceStrategy = FakeEnduranceStrategy(
            distributionToReturn: DamageDistribution(values: [2, 3, 4], weights: [1, 1, 1])
        )
        let repository = FakeItemsRepository()

        withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strengthStrategy
            $0.enduranceDamageReductionDistributionStrategy = enduranceStrategy
        } operation: {
            let service = ElfDamageService()

            for _ in 0..<50 {
                let reduction = service.getRandomEnduranceDamageReduction(20)
                XCTAssertTrue((2...4).contains(reduction), "Reduction \(reduction) should be in range 2-4")
            }
        }
    }

    func testGetRandomEnduranceDamageReduction_EmptyDistribution_ReturnsZero() async {
        // Given
        let strengthStrategy = FakeStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let enduranceStrategy = FakeEnduranceStrategy(
            distributionToReturn: DamageDistribution(values: [], weights: [])
        )
        let repository = FakeItemsRepository()

        let reduction = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strengthStrategy
            $0.enduranceDamageReductionDistributionStrategy = enduranceStrategy
        } operation: {
            let service = ElfDamageService()
            return service.getRandomEnduranceDamageReduction(20)
        }

        XCTAssertEqual(reduction, 0)
    }

    func testCalculateTotalDamage_Hit_ReducesByEndurance() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        // Weapon=10, Strength=5, EndRed=4, Armor=3 -> max(0, 10+5-4-3) = 8
        let pointStatus: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 10, strengthDamage: 5, enduranceReduction: 4, defenderArmor: 3)
        ]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()
            return service.calculateTotalDamage(from: pointStatus)
        }

        XCTAssertEqual(totalDamage, 8)
    }

    func testCalculateTotalDamage_Hit_LargeEnduranceFloorsAtZero() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        // Weapon=5, Strength=3, EndRed=20, Armor=0 -> max(0, 5+3-20-0) = 0
        let pointStatus: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 5, strengthDamage: 3, enduranceReduction: 20, defenderArmor: 0)
        ]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()
            return service.calculateTotalDamage(from: pointStatus)
        }

        XCTAssertEqual(totalDamage, 0)
    }

    /// Pins the crit formula: only the weapon swing is scaled by the
    /// multiplier. Strength bonus and Endurance reduction apply **flat**
    /// after the multiplier, exactly like Armor — they do not scale with
    /// crit. If they did, this test would fail.
    func testCalculateTotalDamage_CritHit_StrengthAndEnduranceAreFlatPostMultiplier() async {
        // Given
        let distribution = DamageDistribution(values: [1], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        // weapon 10 * 2.0 = 20, + strength 5 = 25, - endurance 4 = 21, - armor 2 = 19.
        // (If everything were inside multiplier: (10+5-4)*2 - 2 = 20 → would fail.)
        let pointStatus: [BodyPart: PointStatus] = [
            .body: .critHit(
                weaponDamage: 10,
                strengthDamage: 5,
                enduranceReduction: 4,
                defenderArmor: 2,
                multiplier: 2.0,
                epSpent: 0
            )
        ]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()
            return service.calculateTotalDamage(from: pointStatus)
        }

        XCTAssertEqual(totalDamage, 19, "Only weapon must be multiplied by crit; strength/endurance/armor stay flat")
    }
}

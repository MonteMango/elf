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

    /// Fake strength strategy with predictable output.
    struct FakeStrengthStrategy: StrengthDamageDistributionStrategy {
        let distributionToReturn: DamageDistribution
        func distribution(for strength: Int16) -> DamageDistribution {
            distributionToReturn
        }
    }

    /// Fake reduction strategy. Captures `(stat, coefficient)` per call so
    /// tests can assert the service forwards both arguments unchanged.
    final class FakeReductionStrategy: DamageReductionDistributionStrategy, @unchecked Sendable {
        var distributionToReturn: DamageDistribution = DamageDistribution(values: [0], weights: [1])
        var calls: [(stat: Int16, coefficient: Double)] = []

        func distribution(for stat: Int16, coefficient: Double) -> DamageDistribution {
            calls.append((stat, coefficient))
            return distributionToReturn
        }
    }

    // MARK: - Setup

    /// Wrap every test so `ElfDamageService.init()`'s `@Dependency` reads
    /// always resolve (the strict `testValue` would otherwise fail the test
    /// even when the dependency is irrelevant to its assertions). Individual
    /// tests override the strategy they assert against in their own nested
    /// `withDependencies` block.
    ///
    /// The outer scope seeds the generator so `ElfDamageService`'s roll
    /// methods (which resolve `\.withRandomNumberGenerator` at call time via
    /// their convenience overloads) are deterministic; the inner scope wires
    /// the strategies + sampling service the service-under-test pulls.
    override func invokeTest() {
        withDependencies {
            $0.withRandomNumberGenerator = WithRandomNumberGenerator(
                SeededRandomNumberGenerator(seed: 0xE1F)
            )
        } operation: {
            withDependencies {
                $0.itemsRepository = FakeItemsRepository()
                $0.strengthDamageDistributionStrategy = FakeStrengthStrategy(
                    distributionToReturn: DamageDistribution(values: [0], weights: [1])
                )
                $0.damageReductionDistributionStrategy = FakeReductionStrategy()
                $0.weightedSamplingService = ElfWeightedSamplingService()
            } operation: {
                super.invokeTest()
            }
        }
    }

    // MARK: - Test Helpers

    private func makeWeapon(id: UUID, minDamage: Int16, maxDamage: Int16) -> WeaponItem {
        // swiftlint:disable:next force_try
        try! TestFixtures.weaponItem(
            id: id, handUse: .oneHand,
            minimumAttackPoint: minDamage,
            maximumAttackPoint: maxDamage,
            epBlockCost: 200
        )
    }

    // MARK: - Strength Damage Tests

    func testGetRandomStrengthDamage_ReturnsValueInRange() async {
        let distribution = DamageDistribution(values: [5, 6, 7], weights: [1, 1, 1])
        let strategy = FakeStrengthStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()
            for _ in 0..<50 {
                let damage = service.getRandomStrengthDamage(10)
                XCTAssertTrue((5...7).contains(damage), "Damage \(damage) should be in range 5-7")
            }
        }
    }

    func testGetRandomStrengthDamage_EmptyDistribution_ReturnsZero() async {
        let distribution = DamageDistribution(values: [], weights: [])
        let strategy = FakeStrengthStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()

        let damage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()
            return service.getRandomStrengthDamage(10)
        }

        XCTAssertEqual(damage, 0)
    }

    // MARK: - Weapon Damage Tests

    func testGetWeaponDamage_WithValidWeapon_ReturnsCorrectRange() async {
        let weaponId = UUID()
        let weapon = makeWeapon(id: weaponId, minDamage: 10, maxDamage: 20)
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let repository = FakeItemsRepository()
        repository.items[weaponId] = weapon

        let result = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()
            return service.getWeaponDamage(weaponId: weaponId)
        }

        XCTAssertEqual(result?.minDmg, 10)
        XCTAssertEqual(result?.maxDmg, 20)
    }

    func testGetWeaponDamage_WithNilWeaponId_ReturnsZero() async {
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let repository = FakeItemsRepository()

        let result = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()
            return service.getWeaponDamage(weaponId: nil)
        }

        XCTAssertEqual(result?.minDmg, 0)
        XCTAssertEqual(result?.maxDmg, 0)
    }

    func testGetWeaponDamage_WithNonExistentWeapon_ReturnsZero() async {
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let repository = FakeItemsRepository()

        let result = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()
            return service.getWeaponDamage(weaponId: UUID())
        }

        XCTAssertEqual(result?.minDmg, 0)
        XCTAssertEqual(result?.maxDmg, 0)
    }

    // MARK: - Calculate Total Damage Tests

    func testCalculateTotalDamage_Hit_AppliesArmorReduction() async {
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let repository = FakeItemsRepository()

        // Weapon=10, Strength=5, EndRed=0, Armor=3 → 12.
        let pointStatus: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 3)
        ]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()
            return service.calculateTotalDamage(from: pointStatus)
        }

        XCTAssertEqual(totalDamage, 12)
    }

    func testCalculateTotalDamage_Hit_MinimumZeroDamage() async {
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let repository = FakeItemsRepository()

        let pointStatus: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 5, strengthDamage: 3, enduranceReduction: 0, defenderArmor: 20)
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

    func testCalculateTotalDamage_CritHit_AppliesMultiplier() async {
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let repository = FakeItemsRepository()

        // weapon 10 × 2.0 = 20, + str 5 − end 0 − armor 5 = 20.
        let pointStatus: [BodyPart: PointStatus] = [
            .body: .critHit(weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 5, multiplier: 2.0, epSpent: 0)
        ]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()
            return service.calculateTotalDamage(from: pointStatus)
        }

        XCTAssertEqual(totalDamage, 20)
    }

    func testCalculateTotalDamage_Blocked_NoDamage() async {
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let repository = FakeItemsRepository()

        let pointStatus: [BodyPart: PointStatus] = [.head: .blocked(epSpent: 0)]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()
            return service.calculateTotalDamage(from: pointStatus)
        }

        XCTAssertEqual(totalDamage, 0)
    }

    func testCalculateTotalDamage_Dodged_NoDamage() async {
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let repository = FakeItemsRepository()

        let pointStatus: [BodyPart: PointStatus] = [.body: .dodged(wasCrit: true)]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()
            return service.calculateTotalDamage(from: pointStatus)
        }

        XCTAssertEqual(totalDamage, 0)
    }

    func testCalculateTotalDamage_Multiple_SumsCorrectly() async {
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let repository = FakeItemsRepository()

        // Head 10+5-3=12, Body 20+10-5=25, Legs blocked=0 → 37.
        let pointStatus: [BodyPart: PointStatus] = [
            .head: .hit(weaponDamage: 10, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 3),
            .body: .hit(weaponDamage: 20, strengthDamage: 10, enduranceReduction: 0, defenderArmor: 5),
            .legs: .blocked(epSpent: 0)
        ]

        let totalDamage = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
        } operation: {
            let service = ElfDamageService()
            return service.calculateTotalDamage(from: pointStatus)
        }

        XCTAssertEqual(totalDamage, 37)
    }

    // MARK: - Damage Reduction Tests

    /// Pins the wiring: the service must forward both `stat` and `coefficient`
    /// to the strategy unchanged.
    func testGetRandomDamageReduction_ForwardsStatAndCoefficient() async {
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let reductionStrategy = FakeReductionStrategy()
        reductionStrategy.distributionToReturn = DamageDistribution(values: [2, 3, 4], weights: [1, 1, 1])
        let repository = FakeItemsRepository()

        let reduction = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
            $0.damageReductionDistributionStrategy = reductionStrategy
        } operation: {
            let service = ElfDamageService()
            return service.getRandomDamageReduction(stat: 20, coefficient: 0.18)
        }

        XCTAssertTrue((2...4).contains(reduction))
        XCTAssertEqual(reductionStrategy.calls.count, 1)
        XCTAssertEqual(reductionStrategy.calls.first?.stat, 20)
        XCTAssertEqual(reductionStrategy.calls.first?.coefficient, 0.18)
    }

    func testGetRandomDamageReduction_EmptyDistribution_ReturnsZero() async {
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let reductionStrategy = FakeReductionStrategy()
        reductionStrategy.distributionToReturn = DamageDistribution(values: [], weights: [])
        let repository = FakeItemsRepository()

        let reduction = withDependencies {
            $0.itemsRepository = repository
            $0.strengthDamageDistributionStrategy = strategy
            $0.damageReductionDistributionStrategy = reductionStrategy
        } operation: {
            let service = ElfDamageService()
            return service.getRandomDamageReduction(stat: 20, coefficient: 0.18)
        }

        XCTAssertEqual(reduction, 0)
    }

    func testCalculateTotalDamage_Hit_ReducesByEndurance() async {
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let repository = FakeItemsRepository()

        // 10 + 5 − 4 − 3 = 8.
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
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let repository = FakeItemsRepository()

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
    /// multiplier. Strength bonus and endurance reduction apply flat after
    /// the multiplier, just like Armor — they do NOT scale with crit.
    func testCalculateTotalDamage_CritHit_StrengthAndEnduranceAreFlatPostMultiplier() async {
        let strategy = FakeStrengthStrategy(distributionToReturn: DamageDistribution(values: [1], weights: [1]))
        let repository = FakeItemsRepository()

        // weapon 10 × 2.0 = 20, + str 5 − end 4 − armor 2 = 19.
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

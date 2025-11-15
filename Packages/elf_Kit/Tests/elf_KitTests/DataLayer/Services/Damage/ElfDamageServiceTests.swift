//
//  ElfDamageServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.07.25.
//

import XCTest
import Combine
@testable import elf_Kit

final class ElfDamageServiceTests: XCTestCase {

    // Фейковая стратегия для предсказуемого поведения
    struct FakeStrategy: StrengthDamageDistributionStrategy {
        let distributionToReturn: DamageDistribution

        func distribution(for strength: Int16) -> DamageDistribution {
            return distributionToReturn
        }
    }

    // Фейковый репозиторий
    final class FakeItemsRepository: ItemsRepository {
        nonisolated(unsafe) var items: [UUID: Item] = [:]
        nonisolated(unsafe) var heroItems: HeroItems? = nil
        var heroItemsPublisher: AnyPublisher<HeroItems?, Never> {
            Just(heroItems).eraseToAnyPublisher()
        }

        func loadHeroItems() async throws {}

        func getHeroItem(_ id: UUID) async -> Item? {
            return items[id]
        }
    }

    func testReturnsCorrectMinAndMaxDamage() async throws {
        // given
        let distribution = DamageDistribution(values: [3, 4, 5, 6], weights: [1, 2, 2, 1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        let service = ElfDamageService(itemsRepository: repository, distributionStrategy: strategy)
        
        // when
        let result = await service.getMinMaxStrengthDamage(10)
        
        // then
        XCTAssertEqual(result?.minDmg, 3)
        XCTAssertEqual(result?.maxDmg, 6)
    }
    
    func testReturnsNilWhenValuesIsEmpty() async throws {
        // given
        let distribution = DamageDistribution(values: [], weights: [])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        let service = ElfDamageService(itemsRepository: repository, distributionStrategy: strategy)
        
        // when
        let result = await service.getMinMaxStrengthDamage(10)
        
        // then
        XCTAssertNil(result)
    }
    
    func testWorksWithSingleValue() async throws {
        // given
        let distribution = DamageDistribution(values: [5], weights: [1])
        let strategy = FakeStrategy(distributionToReturn: distribution)
        let repository = FakeItemsRepository()
        let service = ElfDamageService(itemsRepository: repository, distributionStrategy: strategy)
        
        // when
        let result = await service.getMinMaxStrengthDamage(3)
        
        // then
        XCTAssertEqual(result?.minDmg, 5)
        XCTAssertEqual(result?.maxDmg, 5)
    }
}


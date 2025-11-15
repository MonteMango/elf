
//
//  ElfAttributeServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.07.25.
//

import XCTest
import Combine
@testable import elf_Kit

final class ElfAttributeServiceTests: XCTestCase {
    
    // MARK: - Фейковые зависимости

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
    
    final class FixedRandomizer: AttributeRandomizer {
        private var queue: [String]
        private var index = 0
        
        init(queue: [String]) {
            self.queue = queue
        }
        
        func nextAttribute() -> String {
            defer { index += 1 }
            return queue[index % queue.count]
        }
    }
    
    struct TestItem: Item {
        let id: UUID
        let title: String
        let tier: Int16
        let isUnique: Bool?
        let strength: Int16?
        let agility: Int16?
        let power: Int16?
        let instinct: Int16?
        let hitPoints: Int16?
        let manaPoints: Int16?
    }
    
    // MARK: - Тесты
    
    func testFightStyleCritAttributesLevel10() async {
        let service = ElfAttributeService(itemsRepository: FakeItemsRepository())
        let result = await service.getAllFightStyleAttributes(for: .crit, at: 10)
        
        XCTAssertEqual(result.hitPoints, 100)
        XCTAssertEqual(result.manaPoints, 20)
        XCTAssertEqual(result.instinct, 20)
        XCTAssertEqual(result.power, 40)
        XCTAssertEqual(result.agility, 0)
        XCTAssertEqual(result.strength, 0)
    }
    
    func testFightStyleDodgeAttributesLevel10() async {
        let service = ElfAttributeService(itemsRepository: FakeItemsRepository())
        let result = await service.getAllFightStyleAttributes(for: .dodge, at: 10)
        
        XCTAssertEqual(result.hitPoints, 100)
        XCTAssertEqual(result.manaPoints, 20)
        XCTAssertEqual(result.instinct, 20)
        XCTAssertEqual(result.power, 0)
        XCTAssertEqual(result.agility, 40)
        XCTAssertEqual(result.strength, 0)
    }
    
    func testFightStyleDefAttributesLevel10() async {
        let service = ElfAttributeService(itemsRepository: FakeItemsRepository())
        let result = await service.getAllFightStyleAttributes(for: .def, at: 10)
        
        XCTAssertEqual(result.hitPoints, 150)
        XCTAssertEqual(result.manaPoints, 20)
        XCTAssertEqual(result.instinct, 30)
        XCTAssertEqual(result.power, 0)
        XCTAssertEqual(result.agility, 00)
        XCTAssertEqual(result.strength, 20)
    }

    func testRandomLevelAttributesAreDeterministic() async {
        let randomizer = FixedRandomizer(queue: ["hitPoints", "manaPoints", "agility", "strength"])
        let service = ElfAttributeService(itemsRepository: FakeItemsRepository(), randomizer: randomizer)
        
        let result = await service.getRandomLevelAttributes()
        
        XCTAssertEqual(result.hitPoints, 5)
        XCTAssertEqual(result.manaPoints, 5)
        XCTAssertEqual(result.agility, 1)
        XCTAssertEqual(result.strength, 1)
        XCTAssertEqual(result.power, 0)
        XCTAssertEqual(result.instinct, 0)
    }

    func testAllRandomLevelAttributesSumsCorrectly() async {
        let randomizer = FixedRandomizer(queue: ["agility", "strength", "power", "instinct"])
        let service = ElfAttributeService(itemsRepository: FakeItemsRepository(), randomizer: randomizer)
        
        let result = await service.getAllRandomLevelAttributes(for: 2)
        
        XCTAssertEqual(result.agility, 2)
        XCTAssertEqual(result.strength, 2)
        XCTAssertEqual(result.power, 2)
        XCTAssertEqual(result.instinct, 2)
        XCTAssertEqual(result.hitPoints, 0)
        XCTAssertEqual(result.manaPoints, 0)
    }
    
    func testAllRandomAttributesSumsWithWrongAttributeCorrectly() async {
        let randomizer = FixedRandomizer(queue: ["endurance"])
        let service = ElfAttributeService(itemsRepository: FakeItemsRepository(), randomizer: randomizer)
        
        let result = await service.getAllRandomLevelAttributes(for: 1)
        
        XCTAssertEqual(result.agility, 0)
        XCTAssertEqual(result.strength, 0)
        XCTAssertEqual(result.power, 0)
        XCTAssertEqual(result.instinct, 0)
        XCTAssertEqual(result.hitPoints, 0)
        XCTAssertEqual(result.manaPoints, 0)
    }

    func testItemsAttributesAggregation() async {
        let id1 = UUID()
        let id2 = UUID()
        
        let item1 = TestItem(id: id1, title: "Ring", tier: 1, isUnique: nil,
                             strength: 1, agility: nil, power: 2,
                             instinct: 1, hitPoints: 10, manaPoints: nil)
        
        let item2 = TestItem(id: id2, title: "Amulet", tier: 1, isUnique: nil,
                             strength: nil, agility: 3, power: nil,
                             instinct: 4, hitPoints: nil, manaPoints: 5)
        
        let repo = FakeItemsRepository()
        repo.items = [id1: item1, id2: item2]
        
        let service = ElfAttributeService(itemsRepository: repo)
        let result = await service.getAllItemsAttrbutes(for: [id1, id2])
        
        XCTAssertEqual(result.strength, 1)
        XCTAssertEqual(result.power, 2)
        XCTAssertEqual(result.agility, 3)
        XCTAssertEqual(result.instinct, 5)
        XCTAssertEqual(result.hitPoints, 10)
        XCTAssertEqual(result.manaPoints, 5)
    }
}

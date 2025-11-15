//
//  ElfArmorServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.07.25.
//

import Combine
import XCTest
@testable import elf_Kit

final class ElfArmorServiceTests: XCTestCase {
    
    // MARK: - Фейковый предмет, соответствующий протоколам
    
    struct TestItem: Item, HasPhysicalDefense {
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

        let physicalDefensePoint: Int16
        let protectParts: [BodyPart]
        
        init(
            id: UUID = UUID(),
            title: String,
            tier: Int16,
            physicalDefensePoint: Int16,
            protectParts: [BodyPart],
            isUnique: Bool? = nil,
            strength: Int16? = nil,
            agility: Int16? = nil,
            power: Int16? = nil,
            instinct: Int16? = nil,
            hitPoints: Int16? = nil,
            manaPoints: Int16? = nil
        ) {
            self.id = id
            self.title = title
            self.tier = tier
            self.physicalDefensePoint = physicalDefensePoint
            self.protectParts = protectParts
            
            self.isUnique = isUnique
            self.strength = strength
            self.agility = agility
            self.power = power
            self.instinct = instinct
            self.hitPoints = hitPoints
            self.manaPoints = manaPoints
        }
    }
    
    // MARK: - Фейковый репозиторий

    final class FakeItemsRepository: ItemsRepository {
        nonisolated(unsafe) var items: [UUID: Item] = [:]

        nonisolated(unsafe) var heroItems: HeroItems? = nil
        var heroItemsPublisher: AnyPublisher<HeroItems?, Never> {
            Just(heroItems).eraseToAnyPublisher()
        }

        func loadHeroItems() async throws { }
        
        func getHeroItem(_ id: UUID) async -> Item? {
            return items[id]
        }
    }
    
    // MARK: - Тесты
    
    func testSingleItemReturnsCorrectArmor() async throws {
        let id = UUID()
        let item = TestItem(
            id: id,
            title: "Helmet",
            tier: 1,
            physicalDefensePoint: 2,
            protectParts: [.head]
        )

        let repository = FakeItemsRepository()
        repository.items[id] = item

        let service = ElfArmorService(itemsRepository: repository)
        let result = await service.getAllItemsArmor(for: [id])

        XCTAssertEqual(result[.head], 2)
        XCTAssertEqual(result[.body], 0)
        XCTAssertEqual(result[.leftHand], 0)
        XCTAssertEqual(result[.rightHand], 0)
        XCTAssertEqual(result[.legs], 0)
    }
    
    func testMultipleItemsAddArmorTogether() async throws {
        let id1 = UUID()
        let id2 = UUID()

        let item1 = TestItem(
            id: id1,
            title: "Helmet",
            tier: 1,
            physicalDefensePoint: 1,
            protectParts: [.head]
        )

        let item2 = TestItem(
            id: id2,
            title: "Armor",
            tier: 1,
            physicalDefensePoint: 3,
            protectParts: [.head, .body, .leftHand, .rightHand]
        )

        let repository = FakeItemsRepository()
        repository.items[id1] = item1
        repository.items[id2] = item2

        let service = ElfArmorService(itemsRepository: repository)
        let result = await service.getAllItemsArmor(for: [id1, id2])

        XCTAssertEqual(result[.head], 4)
        XCTAssertEqual(result[.body], 3)
        XCTAssertEqual(result[.leftHand], 3)
        XCTAssertEqual(result[.rightHand], 3)
        XCTAssertEqual(result[.legs], 0)
    }

    func testNonDefensiveItemIsIgnored() async throws {
        struct NonDefenseItem: Item {
            let id: UUID
            let title: String
            let tier: Int16

            var isUnique: Bool? = nil
            var strength: Int16? = nil
            var agility: Int16? = nil
            var power: Int16? = nil
            var instinct: Int16? = nil
            var hitPoints: Int16? = nil
            var manaPoints: Int16? = nil
        }

        let id = UUID()
        let item = NonDefenseItem(id: id, title: "Ring", tier: 1)

        let repository = FakeItemsRepository()
        repository.items[id] = item

        let service = ElfArmorService(itemsRepository: repository)
        let result = await service.getAllItemsArmor(for: [id])

        XCTAssertEqual(result.values.reduce(0, +), 0)
    }

    func testMissingItemIsIgnored() async throws {
        let id = UUID() // не добавлен в items

        let repository = FakeItemsRepository()
        let service = ElfArmorService(itemsRepository: repository)
        let result = await service.getAllItemsArmor(for: [id])

        XCTAssertEqual(result.values.reduce(0, +), 0)
    }
}

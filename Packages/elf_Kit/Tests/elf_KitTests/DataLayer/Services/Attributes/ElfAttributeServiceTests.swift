//
//  ElfAttributeServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.07.25.
//

import Dependencies
import XCTest
import Combine
@testable import elf_Kit

/// Tests for ElfAttributeService
///
/// Fight style formulas:
/// - **Crit**: HP=80, Instinct=1*lvl, Power=4*lvl, Strength=1*lvl
/// - **Dodge**: HP=80, Agility=4*lvl, Instinct=1*lvl, Strength=1*lvl
/// - **Def**: HP=80+2*lvl, Instinct=2*lvl, Strength=2*lvl
final class ElfAttributeServiceTests: XCTestCase {

    // MARK: - Фейковые зависимости

    final class FakeItemsRepository: ItemsRepository {
        nonisolated(unsafe) var items: [UUID: Item] = [:]
        nonisolated(unsafe) var heroItems: HeroItems

        init() {
            // Create empty HeroItems for testing
            self.heroItems = HeroItems(
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

    final class FixedRandomizer: AttributeRandomizer, @unchecked Sendable {
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
        let result = withDependencies {
            $0.itemsRepository = FakeItemsRepository()
        } operation: {
            let service = ElfAttributeService()
            return service.getAllFightStyleAttributes(for: .crit, at: 10)
        }

        XCTAssertEqual(result.hitPoints, 80)
        XCTAssertEqual(result.manaPoints, 20)
        XCTAssertEqual(result.instinct, 10)   // 1 * level
        XCTAssertEqual(result.power, 40)      // 4 * level
        XCTAssertEqual(result.agility, 0)
        XCTAssertEqual(result.strength, 10)   // 1 * level
    }

    func testFightStyleDodgeAttributesLevel10() async {
        let result = withDependencies {
            $0.itemsRepository = FakeItemsRepository()
        } operation: {
            let service = ElfAttributeService()
            return service.getAllFightStyleAttributes(for: .dodge, at: 10)
        }

        XCTAssertEqual(result.hitPoints, 80)
        XCTAssertEqual(result.manaPoints, 20)
        XCTAssertEqual(result.instinct, 10)   // 1 * level
        XCTAssertEqual(result.power, 0)
        XCTAssertEqual(result.agility, 40)    // 4 * level
        XCTAssertEqual(result.strength, 10)   // 1 * level
    }

    func testFightStyleDefAttributesLevel10() async {
        let result = withDependencies {
            $0.itemsRepository = FakeItemsRepository()
        } operation: {
            let service = ElfAttributeService()
            return service.getAllFightStyleAttributes(for: .def, at: 10)
        }

        XCTAssertEqual(result.hitPoints, 100) // 80 + 2*10
        XCTAssertEqual(result.manaPoints, 20)
        XCTAssertEqual(result.instinct, 20)   // 2 * level
        XCTAssertEqual(result.power, 0)
        XCTAssertEqual(result.agility, 0)
        XCTAssertEqual(result.strength, 20)   // 2 * level
    }

    func testRandomLevelAttributesAreDeterministic() async {
        let result = withDependencies {
            $0.itemsRepository = FakeItemsRepository()
            $0.attributeRandomizer = FixedRandomizer(queue: ["hitPoints", "manaPoints", "agility", "strength"])
        } operation: {
            let service = ElfAttributeService()
            return service.getRandomLevelAttributes()
        }

        // 4 attributes assigned: hitPoints(+3), manaPoints(+3), agility(+1), strength(+1)
        XCTAssertEqual(result.hitPoints, 3)
        XCTAssertEqual(result.manaPoints, 3)
        XCTAssertEqual(result.agility, 1)
        XCTAssertEqual(result.strength, 1)
        XCTAssertEqual(result.power, 0)
        XCTAssertEqual(result.instinct, 0)
    }

    func testAllRandomLevelAttributesSumsCorrectly() async {
        let result = withDependencies {
            $0.itemsRepository = FakeItemsRepository()
            $0.attributeRandomizer = FixedRandomizer(queue: ["agility", "strength", "power", "instinct"])
        } operation: {
            let service = ElfAttributeService()
            return service.getAllRandomLevelAttributes(for: 2)
        }

        // Due to parallel execution with TaskGroup, we can't guarantee exact distribution
        // But we can verify total points assigned: 2 levels * 4 points = 8 points total
        let totalPoints = result.agility + result.strength + result.power + result.instinct
        XCTAssertEqual(totalPoints, 8, "Total points should be 8 (2 levels * 4 points per level)")

        // Verify no HP/MP were assigned (queue doesn't contain hitPoints/manaPoints)
        XCTAssertEqual(result.hitPoints, 0)
        XCTAssertEqual(result.manaPoints, 0)
    }

    func testAllRandomAttributesSumsWithWrongAttributeCorrectly() async {
        let result = withDependencies {
            $0.itemsRepository = FakeItemsRepository()
            $0.attributeRandomizer = FixedRandomizer(queue: ["endurance"])
        } operation: {
            let service = ElfAttributeService()
            return service.getAllRandomLevelAttributes(for: 1)
        }

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

        let result = withDependencies {
            $0.itemsRepository = repo
        } operation: {
            let service = ElfAttributeService()
            return service.getAllItemsAttributes(for: [id1, id2])
        }

        XCTAssertEqual(result.strength, 1)
        XCTAssertEqual(result.power, 2)
        XCTAssertEqual(result.agility, 3)
        XCTAssertEqual(result.instinct, 5)
        XCTAssertEqual(result.hitPoints, 10)
        XCTAssertEqual(result.manaPoints, 5)
    }
}

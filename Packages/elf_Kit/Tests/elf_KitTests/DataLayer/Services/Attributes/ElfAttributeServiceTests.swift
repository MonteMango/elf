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
/// - **Crit**: HP=80, Instinct=1*lvl, Power=4*lvl, Strength=1*lvl, Endurance=0
/// - **Dodge**: HP=80, Agility=4*lvl, Instinct=1*lvl, Strength=1*lvl, Endurance=0
/// - **Def**: HP=80, Instinct=2*lvl, Strength=1*lvl, Endurance=3*lvl
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
        let endurance: Int16?
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

        XCTAssertEqual(result.hitPoints, 130)  // 80 + 5 * level
        XCTAssertEqual(result.manaPoints, 20)
        XCTAssertEqual(result.instinct, 10)   // 1 * level
        XCTAssertEqual(result.power, 40)      // 4 * level
        XCTAssertEqual(result.agility, 0)
        XCTAssertEqual(result.strength, 10)   // 1 * level
        XCTAssertEqual(result.endurance, 0)
    }

    func testFightStyleDodgeAttributesLevel10() async {
        let result = withDependencies {
            $0.itemsRepository = FakeItemsRepository()
        } operation: {
            let service = ElfAttributeService()
            return service.getAllFightStyleAttributes(for: .dodge, at: 10)
        }

        XCTAssertEqual(result.hitPoints, 130)  // 80 + 5 * level
        XCTAssertEqual(result.manaPoints, 20)
        XCTAssertEqual(result.instinct, 10)   // 1 * level
        XCTAssertEqual(result.power, 0)
        XCTAssertEqual(result.agility, 40)    // 4 * level
        XCTAssertEqual(result.strength, 10)   // 1 * level
        XCTAssertEqual(result.endurance, 0)
    }

    func testFightStyleDefAttributesLevel10() async {
        let result = withDependencies {
            $0.itemsRepository = FakeItemsRepository()
        } operation: {
            let service = ElfAttributeService()
            return service.getAllFightStyleAttributes(for: .def, at: 10)
        }

        XCTAssertEqual(result.hitPoints, 130)  // 80 + 5 * level
        XCTAssertEqual(result.manaPoints, 20)
        XCTAssertEqual(result.instinct, 20)   // 2 * level
        XCTAssertEqual(result.power, 0)
        XCTAssertEqual(result.agility, 0)
        XCTAssertEqual(result.strength, 10)   // 1 * level
        XCTAssertEqual(result.endurance, 30)  // 3 * level
    }

    func testRandomLevelAttributesAreDeterministic() async {
        let result = withDependencies {
            $0.itemsRepository = FakeItemsRepository()
            $0.attributeRandomizer = FixedRandomizer(queue: ["agility", "strength", "endurance", "power"])
        } operation: {
            let service = ElfAttributeService()
            return service.getRandomLevelAttributes()
        }

        // 4 attributes assigned: agility(+1), strength(+1), endurance(+1), power(+1)
        XCTAssertEqual(result.hitPoints, 0)
        XCTAssertEqual(result.manaPoints, 0)
        XCTAssertEqual(result.agility, 1)
        XCTAssertEqual(result.strength, 1)
        XCTAssertEqual(result.power, 1)
        XCTAssertEqual(result.instinct, 0)
        XCTAssertEqual(result.endurance, 1)
    }

    func testAllRandomLevelAttributesSumsCorrectly() async {
        let result = withDependencies {
            $0.itemsRepository = FakeItemsRepository()
            $0.attributeRandomizer = FixedRandomizer(queue: ["agility", "strength", "power", "instinct", "endurance"])
        } operation: {
            let service = ElfAttributeService()
            return service.getAllRandomLevelAttributes(for: 2)
        }

        // 2 levels * 4 points each = 8 total points assigned across the five stats
        let totalPoints = result.agility + result.strength + result.power + result.instinct + result.endurance
        XCTAssertEqual(totalPoints, 8, "Total points should be 8 (2 levels * 4 points per level)")

        // Verify no HP/MP were assigned (queue doesn't contain hitPoints/manaPoints)
        XCTAssertEqual(result.hitPoints, 0)
        XCTAssertEqual(result.manaPoints, 0)
    }

    func testAllRandomAttributesSumsWithWrongAttributeCorrectly() async {
        let result = withDependencies {
            $0.itemsRepository = FakeItemsRepository()
            $0.attributeRandomizer = FixedRandomizer(queue: ["unknown"])
        } operation: {
            let service = ElfAttributeService()
            return service.getAllRandomLevelAttributes(for: 1)
        }

        XCTAssertEqual(result.agility, 0)
        XCTAssertEqual(result.strength, 0)
        XCTAssertEqual(result.power, 0)
        XCTAssertEqual(result.instinct, 0)
        XCTAssertEqual(result.endurance, 0)
        XCTAssertEqual(result.hitPoints, 0)
        XCTAssertEqual(result.manaPoints, 0)
    }

    func testItemsAttributesAggregation() async {
        let id1 = UUID()
        let id2 = UUID()

        let item1 = TestItem(id: id1, title: "Ring", tier: 1, isUnique: nil,
                             strength: 1, agility: nil, power: 2,
                             instinct: 1, endurance: 2, hitPoints: 10, manaPoints: nil)

        let item2 = TestItem(id: id2, title: "Amulet", tier: 1, isUnique: nil,
                             strength: nil, agility: 3, power: nil,
                             instinct: 4, endurance: nil, hitPoints: nil, manaPoints: 5)

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
        XCTAssertEqual(result.endurance, 2)
        XCTAssertEqual(result.hitPoints, 10)
        XCTAssertEqual(result.manaPoints, 5)
    }
}

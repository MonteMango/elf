//
//  ElfItemsRepositoryTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.07.25.
//

import XCTest
@testable import elf_Kit

final class ElfItemsRepositoryTests: XCTestCase {
    
    // MARK: - Фейковый загрузчик
    
    final class FakeDataLoader: DataLoader {
        enum Mode {
            case valid
            case invalidJSON
            case error
        }

        var mode: Mode
        var customJSON: String?

        init(mode: Mode, customJSON: String? = nil) {
            self.mode = mode
            self.customJSON = customJSON
        }

        func loadHeroItemsData() throws -> Data {
            switch mode {
            case .valid:
                let json = customJSON ?? """
                {
                  "version": "1.0",
                  "helmets": [],
                  "gloves": [],
                  "shoes": [],
                  "upperBodies": [],
                  "bottomBodies": [],
                  "robes": [],
                  "weapons": [
                    {
                      "id": "\(UUID())",
                      "title": "Sword of Truth",
                      "tier": 4,
                      "minimumAttackPoint": 3,
                      "maximumAttackPoint": 5,
                      "handUse": "secondary"
                    }
                  ],
                  "shields": [],
                  "rings": [],
                  "necklaces": [],
                  "earrings": []
                }
                """
                return Data(json.utf8)

            case .invalidJSON:
                return Data("INVALID JSON".utf8)

            case .error:
                throw NSError(domain: "FakeError", code: 999, userInfo: nil)
            }
        }

        func loadMonstersData() throws -> Data {
            // Return minimal valid monsters data for tests
            let json = """
            {
              "version": "1.0",
              "upperWorld": {},
              "middleWorld": {},
              "lowerWorld": {}
            }
            """
            return Data(json.utf8)
        }

        func loadMaterialsData() throws -> Data {
            // Return minimal valid materials data for tests
            let json = """
            {
              "version": "1.0",
              "monsters_drop": []
            }
            """
            return Data(json.utf8)
        }

        func loadFishData() throws -> Data {
            // Return minimal valid fish data for tests
            let json = """
            {
              "version": "1.0",
              "effects": [],
              "areas": {},
              "fish": []
            }
            """
            return Data(json.utf8)
        }

        func loadHerbsData() throws -> Data {
            // Return minimal valid herbs data for tests
            let json = """
            {
              "version": "1.0",
              "effects": [],
              "areas": {},
              "herbs": []
            }
            """
            return Data(json.utf8)
        }
    }
    
    // MARK: - Тесты

    func testInitializationLoadsHeroItems() throws {
        let loader = FakeDataLoader(mode: .valid)
        let repository = ElfItemsRepository(dataLoader: loader)

        XCTAssertEqual(repository.heroItems.weapons.count, 1)
    }

    func testGetHeroItemReturnsCorrectItem() throws {
        let weaponID = UUID()
        let json = """
        {
          "version": "1.0",
          "helmets": [],
          "gloves": [],
          "shoes": [],
          "upperBodies": [],
          "bottomBodies": [],
          "robes": [],
          "weapons": [
            {
              "id": "\(weaponID)",
              "title": "Sword of Truth",
              "tier": 4,
              "minimumAttackPoint": 3,
              "maximumAttackPoint": 5,
              "handUse": "secondary"
            }
          ],
          "shields": [],
          "rings": [],
          "necklaces": [],
          "earrings": []
        }
        """
        let loader = FakeDataLoader(mode: .valid, customJSON: json)
        let repository = ElfItemsRepository(dataLoader: loader)

        let found = repository.getHeroItem(weaponID)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.title, "Sword of Truth")
    }

    func testInitializationFallsBackToEmptyDataOnInvalidJSON() {
        let loader = FakeDataLoader(mode: .invalidJSON)

        // With the new graceful fallback, this should not crash
        // Instead it should use empty hero items
        let repository = ElfItemsRepository(dataLoader: loader)

        // Verify empty data was used
        XCTAssertEqual(repository.heroItems.weapons.count, 0)
        XCTAssertEqual(repository.heroItems.helmets.count, 0)
    }

    func testInitializationFallsBackToEmptyDataOnDataLoaderError() {
        let loader = FakeDataLoader(mode: .error)

        // With the new graceful fallback, this should not crash
        // Instead it should use empty hero items
        let repository = ElfItemsRepository(dataLoader: loader)

        // Verify empty data was used
        XCTAssertEqual(repository.heroItems.weapons.count, 0)
        XCTAssertEqual(repository.heroItems.helmets.count, 0)
    }
}

//
//  ElfItemsRepositoryTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.07.25.
//

import os.log
import XCTest
@testable import elf_Kit

final class ElfItemsRepositoryTests: XCTestCase {

    // MARK: - Fake Data Loader

    final class FakeDataLoader: DataLoader, @unchecked Sendable {
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

        func loadJSON(_ resourceName: String) async throws -> Data {
            switch resourceName {
            case "HeroItems":
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
                          "handUse": "oneHand",
                          "epBlockCost": 200
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
            default:
                return Data("{}".utf8)
            }
        }

        func loadAndDecode<T: Decodable>(
            resourceName: String,
            fallback: @autoclosure () -> T,
            log: OSLog
        ) async -> T {
            guard let data = try? await loadJSON(resourceName),
                  let decoded = try? JSONDecoder().decode(T.self, from: data) else {
                return fallback()
            }
            return decoded
        }
    }

    // MARK: - Helpers

    private func makeRepository(loader: FakeDataLoader) async -> ElfItemsRepository {
        let log = OSLog(subsystem: "com.elfy.kit.tests", category: "ItemsRepository")
        let data: HeroItems = await loader.loadAndDecode(resourceName: "HeroItems", fallback: .empty, log: log)
        return ElfItemsRepository(heroItems: data)
    }

    // MARK: - Tests

    func testInitializationLoadsHeroItems() async throws {
        let repository = await makeRepository(loader: FakeDataLoader(mode: .valid))

        let weapons = await repository.getItems(for: .weapons)
        XCTAssertEqual(weapons.count, 1)
    }

    func testGetHeroItemReturnsCorrectItem() async throws {
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
              "handUse": "oneHand",
              "epBlockCost": 200
            }
          ],
          "shields": [],
          "rings": [],
          "necklaces": [],
          "earrings": []
        }
        """
        let repository = await makeRepository(loader: FakeDataLoader(mode: .valid, customJSON: json))

        let found = await repository.getHeroItem(ItemID(rawValue: weaponID))
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.title, "Sword of Truth")
    }

    func testInitializationFallsBackToEmptyDataOnInvalidJSON() async {
        let repository = await makeRepository(loader: FakeDataLoader(mode: .invalidJSON))

        let weapons = await repository.getItems(for: .weapons)
        let helmets = await repository.getItems(for: .helmet)
        XCTAssertEqual(weapons.count, 0)
        XCTAssertEqual(helmets.count, 0)
    }

    func testInitializationFallsBackToEmptyDataOnDataLoaderError() async {
        let repository = await makeRepository(loader: FakeDataLoader(mode: .error))

        let weapons = await repository.getItems(for: .weapons)
        let helmets = await repository.getItems(for: .helmet)
        XCTAssertEqual(weapons.count, 0)
        XCTAssertEqual(helmets.count, 0)
    }
}

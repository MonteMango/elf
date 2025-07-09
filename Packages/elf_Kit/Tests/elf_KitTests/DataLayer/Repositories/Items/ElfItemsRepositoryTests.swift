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
        
        func loadHeroItemsData() async throws -> Data {
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
    }
    
    // MARK: - Тесты
    
    func testLoadHeroItemsPublishesItems() async throws {
        let loader = FakeDataLoader(mode: .valid)
        let repository = ElfItemsRepository(dataLoader: loader)
        
        try await repository.loadHeroItems()
        
        XCTAssertNotNil(repository.heroItems)
        XCTAssertEqual(repository.heroItems?.weapons.count, 1)
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
        
        try await repository.loadHeroItems()
        
        let found = await repository.getHeroItem(weaponID)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.title, "Sword of Truth")
    }
    
    func testLoadHeroItemsThrowsOnInvalidJSON() async {
        let loader = FakeDataLoader(mode: .invalidJSON)
        let repository = ElfItemsRepository(dataLoader: loader)
        
        do {
            try await repository.loadHeroItems()
            XCTFail("Expected error was not thrown")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testLoadHeroItemsThrowsOnDataLoaderError() async {
        let loader = FakeDataLoader(mode: .error)
        let repository = ElfItemsRepository(dataLoader: loader)
        
        do {
            try await repository.loadHeroItems()
            XCTFail("Expected error was not thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "FakeError")
            XCTAssertEqual((error as NSError).code, 999)
        }
    }
}

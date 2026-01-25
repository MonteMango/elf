//
//  ElfFishRepositoryTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 20.01.26.
//

import XCTest
@testable import elf_Kit

final class ElfFishRepositoryTests: XCTestCase {

    // MARK: - Fish UUIDs

    enum FishID {
        static let sunny = UUID(uuidString: "A1B2C3D4-1111-4111-8111-111111111111")!
        static let dewdrop = UUID(uuidString: "A1B2C3D4-2222-4222-8222-222222222222")!
        static let pebble = UUID(uuidString: "A1B2C3D4-3333-4333-8333-333333333333")!
        static let whisker = UUID(uuidString: "A1B2C3D4-4444-4444-8444-444444444444")!
        static let bristle = UUID(uuidString: "A1B2C3D4-5555-4555-8555-555555555555")!
        static let duskfin = UUID(uuidString: "A1B2C3D4-6666-4666-8666-666666666666")!
        static let ember = UUID(uuidString: "A1B2C3D4-7777-4777-8777-777777777777")!
        static let dancer = UUID(uuidString: "A1B2C3D4-8888-4888-8888-888888888888")!
        static let ribbontail = UUID(uuidString: "A1B2C3D4-9999-4999-8999-999999999999")!
        static let streamer = UUID(uuidString: "A1B2C3D4-AAAA-4AAA-8AAA-AAAAAAAAAAAA")!
        static let swallowtail = UUID(uuidString: "A1B2C3D4-BBBB-4BBB-8BBB-BBBBBBBBBBBB")!
    }

    // MARK: - Fake Data Loader

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
            return Data("{}".utf8)
        }

        func loadMonstersData() throws -> Data {
            return Data("{}".utf8)
        }

        func loadMaterialsData() throws -> Data {
            return Data("{}".utf8)
        }

        func loadFishData() throws -> Data {
            switch mode {
            case .valid:
                let json = customJSON ?? Self.validFishJSON
                return Data(json.utf8)

            case .invalidJSON:
                return Data("INVALID JSON".utf8)

            case .error:
                throw NSError(domain: "FakeError", code: 999, userInfo: nil)
            }
        }

        static let validFishJSON = """
        {
          "version": "1.0",
          "effects": [
            { "id": "E1F2A3B4-0001-4001-8001-000000000001", "effectType": "arcane", "title": "Arcane", "description": "Pure magical energy" },
            { "id": "E1F2A3B4-0002-4002-8002-000000000002", "effectType": "flame", "title": "Flame", "description": "Fire magic essence" },
            { "id": "E1F2A3B4-0003-4003-8003-000000000003", "effectType": "frost", "title": "Frost", "description": "Ice magic essence" },
            { "id": "E1F2A3B4-0004-4004-8004-000000000004", "effectType": "storm", "title": "Storm", "description": "Lightning and wind essence" },
            { "id": "E1F2A3B4-0005-4005-8005-000000000005", "effectType": "shadow", "title": "Shadow", "description": "Dark magic essence" },
            { "id": "E1F2A3B4-0006-4006-8006-000000000006", "effectType": "radiance", "title": "Radiance", "description": "Light magic essence" },
            { "id": "E1F2A3B4-0007-4007-8007-000000000007", "effectType": "spirit", "title": "Spirit", "description": "Spiritual energy" },
            { "id": "E1F2A3B4-0008-4008-8008-000000000008", "effectType": "venom", "title": "Venom", "description": "Poison magic essence" }
          ],
          "areas": {
            "forest_pond": {
              "title": "Forest Pond",
              "fish": ["A1B2C3D4-1111-4111-8111-111111111111", "A1B2C3D4-2222-4222-8222-222222222222", "A1B2C3D4-3333-4333-8333-333333333333", "A1B2C3D4-4444-4444-8444-444444444444", "A1B2C3D4-5555-4555-8555-555555555555", "A1B2C3D4-6666-4666-8666-666666666666", "A1B2C3D4-7777-4777-8777-777777777777", "A1B2C3D4-8888-4888-8888-888888888888", "A1B2C3D4-9999-4999-8999-999999999999", "A1B2C3D4-AAAA-4AAA-8AAA-AAAAAAAAAAAA", "A1B2C3D4-BBBB-4BBB-8BBB-BBBBBBBBBBBB"]
            }
          },
          "fish": [
            {
              "id": "A1B2C3D4-1111-4111-8111-111111111111",
              "title": "Sunny",
              "imageName": "fish_sunny",
              "description": "A bright golden fish that glows with warm light.",
              "tier": 4,
              "baseCatchChance": 0.35,
              "effects": [{ "type": "radiance", "amount": 1 }]
            },
            {
              "id": "A1B2C3D4-2222-4222-8222-222222222222",
              "title": "Dewdrop",
              "imageName": "fish_dewdrop",
              "description": "A pale blue fish covered in glistening droplets.",
              "tier": 4,
              "baseCatchChance": 0.35,
              "effects": [{ "type": "frost", "amount": 1 }]
            },
            {
              "id": "A1B2C3D4-3333-4333-8333-333333333333",
              "title": "Pebble",
              "imageName": "fish_pebble",
              "description": "A small grey fish with stone-like scales.",
              "tier": 4,
              "baseCatchChance": 0.35,
              "effects": [{ "type": "arcane", "amount": 1 }]
            },
            {
              "id": "A1B2C3D4-4444-4444-8444-444444444444",
              "title": "Whisker",
              "imageName": "fish_whisker",
              "description": "A wise-looking fish with long sensory whiskers.",
              "tier": 4,
              "baseCatchChance": 0.30,
              "effects": [{ "type": "spirit", "amount": 1 }]
            },
            {
              "id": "A1B2C3D4-5555-4555-8555-555555555555",
              "title": "Bristle",
              "imageName": "fish_bristle",
              "description": "A spiky fish with venomous fins.",
              "tier": 3,
              "baseCatchChance": 0.20,
              "effects": [{ "type": "venom", "amount": 1 }, { "type": "shadow", "amount": 1 }]
            },
            {
              "id": "A1B2C3D4-6666-4666-8666-666666666666",
              "title": "Duskfin",
              "imageName": "fish_duskfin",
              "description": "A twilight fish that swims between light and shadow.",
              "tier": 3,
              "baseCatchChance": 0.20,
              "effects": [{ "type": "shadow", "amount": 1 }, { "type": "frost", "amount": 1 }]
            },
            {
              "id": "A1B2C3D4-7777-4777-8777-777777777777",
              "title": "Ember",
              "imageName": "fish_ember",
              "description": "A warm fish with scales that flicker like flames.",
              "tier": 3,
              "baseCatchChance": 0.18,
              "effects": [{ "type": "flame", "amount": 1 }, { "type": "arcane", "amount": 1 }]
            },
            {
              "id": "A1B2C3D4-8888-4888-8888-888888888888",
              "title": "Dancer",
              "imageName": "fish_dancer",
              "description": "An elegant fish that moves with supernatural grace.",
              "tier": 2,
              "baseCatchChance": 0.10,
              "effects": [{ "type": "storm", "amount": 1 }, { "type": "spirit", "amount": 1 }, { "type": "arcane", "amount": 1 }]
            },
            {
              "id": "A1B2C3D4-9999-4999-8999-999999999999",
              "title": "Ribbontail",
              "imageName": "fish_ribbontail",
              "description": "A magnificent fish with flowing, ribbon-like fins.",
              "tier": 2,
              "baseCatchChance": 0.10,
              "effects": [{ "type": "radiance", "amount": 2 }, { "type": "flame", "amount": 1 }]
            },
            {
              "id": "A1B2C3D4-AAAA-4AAA-8AAA-AAAAAAAAAAAA",
              "title": "Streamer",
              "imageName": "fish_streamer",
              "description": "A mystical fish trailing streams of pure magic.",
              "tier": 1,
              "baseCatchChance": 0.05,
              "effects": [{ "type": "arcane", "amount": 2 }, { "type": "storm", "amount": 1 }, { "type": "spirit", "amount": 1 }]
            },
            {
              "id": "A1B2C3D4-BBBB-4BBB-8BBB-BBBBBBBBBBBB",
              "title": "Swallowtail",
              "imageName": "fish_swallowtail",
              "description": "A legendary fish embodying the balance of light and darkness.",
              "tier": 1,
              "baseCatchChance": 0.05,
              "effects": [{ "type": "radiance", "amount": 2 }, { "type": "shadow", "amount": 1 }, { "type": "frost", "amount": 1 }]
            }
          ]
        }
        """
    }

    // MARK: - JSON Loading Tests

    func testJSONParsesWithoutErrors() throws {
        let loader = FakeDataLoader(mode: .valid)
        let repository = ElfFishRepository(dataLoader: loader)

        XCTAssertEqual(repository.fishData.version, "1.0")
    }

    func testAllElevenFishLoaded() throws {
        let loader = FakeDataLoader(mode: .valid)
        let repository = ElfFishRepository(dataLoader: loader)

        XCTAssertEqual(repository.getAllFish().count, 11)
    }

    func testEffectsDecodeCorrectly() throws {
        let loader = FakeDataLoader(mode: .valid)
        let repository = ElfFishRepository(dataLoader: loader)

        // Check Bristle effects (2 effects: venom and shadow)
        let bristle = repository.getFish(id: FishID.bristle)
        XCTAssertNotNil(bristle)
        XCTAssertEqual(bristle?.effects.count, 2)
        XCTAssertEqual(bristle?.effects[0].type, .venom)
        XCTAssertEqual(bristle?.effects[0].amount, 1)
        XCTAssertEqual(bristle?.effects[1].type, .shadow)
        XCTAssertEqual(bristle?.effects[1].amount, 1)

        // Check Ribbontail effects (radiance amount: 2)
        let ribbontail = repository.getFish(id: FishID.ribbontail)
        XCTAssertNotNil(ribbontail)
        XCTAssertEqual(ribbontail?.effects[0].type, .radiance)
        XCTAssertEqual(ribbontail?.effects[0].amount, 2)
    }

    func testForestPondAreaContainsAllFish() throws {
        let loader = FakeDataLoader(mode: .valid)
        let repository = ElfFishRepository(dataLoader: loader)

        let forestPondFish = repository.getFishForArea("forest_pond")
        XCTAssertEqual(forestPondFish.count, 11)

        // Check that all fish are present
        let fishIds = Set(forestPondFish.map { $0.id })
        let expectedIds: Set<UUID> = [
            FishID.sunny, FishID.dewdrop, FishID.pebble, FishID.whisker, FishID.bristle,
            FishID.duskfin, FishID.ember, FishID.dancer, FishID.ribbontail, FishID.streamer, FishID.swallowtail
        ]
        XCTAssertEqual(fishIds, expectedIds)
    }

    // MARK: - Method Tests

    func testGetFishReturnsCorrectFish() throws {
        let loader = FakeDataLoader(mode: .valid)
        let repository = ElfFishRepository(dataLoader: loader)

        let sunny = repository.getFish(id: FishID.sunny)
        XCTAssertNotNil(sunny)
        XCTAssertEqual(sunny?.title, "Sunny")
        XCTAssertEqual(sunny?.imageName, "fish_sunny")
        XCTAssertEqual(sunny?.tier, 4)
        XCTAssertEqual(sunny?.baseCatchChance, 0.35)
    }

    func testGetFishReturnsNilForUnknownId() throws {
        let loader = FakeDataLoader(mode: .valid)
        let repository = ElfFishRepository(dataLoader: loader)

        let unknown = repository.getFish(id: UUID())
        XCTAssertNil(unknown)
    }

    func testGetEffectDefinitionReturnsCorrectEffect() throws {
        let loader = FakeDataLoader(mode: .valid)
        let repository = ElfFishRepository(dataLoader: loader)

        let arcane = repository.getEffectDefinition("arcane")
        XCTAssertNotNil(arcane)
        XCTAssertEqual(arcane?.effectType, "arcane")
        XCTAssertEqual(arcane?.title, "Arcane")
        XCTAssertEqual(arcane?.description, "Pure magical energy")
    }

    func testGetEffectDefinitionReturnsNilForUnknownId() throws {
        let loader = FakeDataLoader(mode: .valid)
        let repository = ElfFishRepository(dataLoader: loader)

        let unknown = repository.getEffectDefinition("unknown_effect")
        XCTAssertNil(unknown)
    }

    func testGetFishForAreaReturnsEmptyForUnknownArea() throws {
        let loader = FakeDataLoader(mode: .valid)
        let repository = ElfFishRepository(dataLoader: loader)

        let fish = repository.getFishForArea("unknown_area")
        XCTAssertTrue(fish.isEmpty)
    }

    // MARK: - Error Handling Tests

    func testInitializationFallsBackToEmptyDataOnInvalidJSON() {
        let loader = FakeDataLoader(mode: .invalidJSON)
        let repository = ElfFishRepository(dataLoader: loader)

        XCTAssertEqual(repository.getAllFish().count, 0)
        XCTAssertEqual(repository.fishData.version, "1.0-empty")
    }

    func testInitializationFallsBackToEmptyDataOnDataLoaderError() {
        let loader = FakeDataLoader(mode: .error)
        let repository = ElfFishRepository(dataLoader: loader)

        XCTAssertEqual(repository.getAllFish().count, 0)
        XCTAssertEqual(repository.fishData.version, "1.0-empty")
    }

    // MARK: - Fish Tier Tests

    func testFishTiersAreCorrect() throws {
        let loader = FakeDataLoader(mode: .valid)
        let repository = ElfFishRepository(dataLoader: loader)

        // Tier 4 (common)
        XCTAssertEqual(repository.getFish(id: FishID.sunny)?.tier, 4)
        XCTAssertEqual(repository.getFish(id: FishID.dewdrop)?.tier, 4)
        XCTAssertEqual(repository.getFish(id: FishID.pebble)?.tier, 4)
        XCTAssertEqual(repository.getFish(id: FishID.whisker)?.tier, 4)

        // Tier 3 (uncommon)
        XCTAssertEqual(repository.getFish(id: FishID.bristle)?.tier, 3)
        XCTAssertEqual(repository.getFish(id: FishID.duskfin)?.tier, 3)
        XCTAssertEqual(repository.getFish(id: FishID.ember)?.tier, 3)

        // Tier 2 (rare)
        XCTAssertEqual(repository.getFish(id: FishID.dancer)?.tier, 2)
        XCTAssertEqual(repository.getFish(id: FishID.ribbontail)?.tier, 2)

        // Tier 1 (legendary)
        XCTAssertEqual(repository.getFish(id: FishID.streamer)?.tier, 1)
        XCTAssertEqual(repository.getFish(id: FishID.swallowtail)?.tier, 1)
    }
}

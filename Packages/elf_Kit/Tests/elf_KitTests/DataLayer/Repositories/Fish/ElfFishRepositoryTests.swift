//
//  ElfFishRepositoryTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 20.01.26.
//

import os.log
import XCTest
@testable import elf_Kit

final class ElfFishRepositoryTests: XCTestCase {

    // MARK: - Fish UUIDs

    enum TestFishID {
        static let sunny = FishID(rawValue: UUID(uuidString: "A1B2C3D4-1111-4111-8111-111111111111")!)
        static let dewdrop = FishID(rawValue: UUID(uuidString: "A1B2C3D4-2222-4222-8222-222222222222")!)
        static let pebble = FishID(rawValue: UUID(uuidString: "A1B2C3D4-3333-4333-8333-333333333333")!)
        static let whisker = FishID(rawValue: UUID(uuidString: "A1B2C3D4-4444-4444-8444-444444444444")!)
        static let bristle = FishID(rawValue: UUID(uuidString: "A1B2C3D4-5555-4555-8555-555555555555")!)
        static let duskfin = FishID(rawValue: UUID(uuidString: "A1B2C3D4-6666-4666-8666-666666666666")!)
        static let ember = FishID(rawValue: UUID(uuidString: "A1B2C3D4-7777-4777-8777-777777777777")!)
        static let dancer = FishID(rawValue: UUID(uuidString: "A1B2C3D4-8888-4888-8888-888888888888")!)
        static let ribbontail = FishID(rawValue: UUID(uuidString: "A1B2C3D4-9999-4999-8999-999999999999")!)
        static let streamer = FishID(rawValue: UUID(uuidString: "A1B2C3D4-AAAA-4AAA-8AAA-AAAAAAAAAAAA")!)
        static let swallowtail = FishID(rawValue: UUID(uuidString: "A1B2C3D4-BBBB-4BBB-8BBB-BBBBBBBBBBBB")!)
    }

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

        func loadJSON(_ resourceName: String) throws -> Data {
            switch resourceName {
            case "Fish":
                switch mode {
                case .valid:
                    let json = customJSON ?? Self.validFishJSON
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

    // MARK: - Helpers

    private func makeRepository(loader: FakeDataLoader) -> ArrayRepository<Fish> {
        let log = OSLog(subsystem: "com.elfy.kit.tests", category: "FishRepository")
        let data: FishData = loader.loadAndDecode(resourceName: "Fish", fallback: .empty, log: log)
        return ArrayRepository(items: data.items)
    }

    // MARK: - JSON Loading Tests

    func testAllElevenFishLoaded() async throws {
        let repository = makeRepository(loader: FakeDataLoader(mode: .valid))

        let allFish = await repository.getAll()
        XCTAssertEqual(allFish.count, 11)
    }

    func testEffectsDecodeCorrectly() async throws {
        let repository = makeRepository(loader: FakeDataLoader(mode: .valid))

        // Check Bristle effects (2 effects: venom and shadow)
        let bristle = await repository.getById(id: TestFishID.bristle)
        XCTAssertNotNil(bristle)
        XCTAssertEqual(bristle?.effects.count, 2)
        XCTAssertEqual(bristle?.effects[0].type, .venom)
        XCTAssertEqual(bristle?.effects[0].amount, 1)
        XCTAssertEqual(bristle?.effects[1].type, .shadow)
        XCTAssertEqual(bristle?.effects[1].amount, 1)

        // Check Ribbontail effects (radiance amount: 2)
        let ribbontail = await repository.getById(id: TestFishID.ribbontail)
        XCTAssertNotNil(ribbontail)
        XCTAssertEqual(ribbontail?.effects[0].type, .radiance)
        XCTAssertEqual(ribbontail?.effects[0].amount, 2)
    }

    // MARK: - Method Tests

    func testGetFishReturnsCorrectFish() async throws {
        let repository = makeRepository(loader: FakeDataLoader(mode: .valid))

        let sunny = await repository.getById(id: TestFishID.sunny)
        XCTAssertNotNil(sunny)
        XCTAssertEqual(sunny?.title, "Sunny")
        XCTAssertEqual(sunny?.imageName, "fish_sunny")
        XCTAssertEqual(sunny?.tier, .common)
        XCTAssertEqual(sunny?.baseCatchChance, 0.35)
    }

    func testGetFishReturnsNilForUnknownId() async throws {
        let repository = makeRepository(loader: FakeDataLoader(mode: .valid))

        let unknown = await repository.getById(id: FishID())
        XCTAssertNil(unknown)
    }

    // MARK: - Error Handling Tests

    func testInitializationFallsBackToEmptyDataOnInvalidJSON() async {
        let repository = makeRepository(loader: FakeDataLoader(mode: .invalidJSON))

        let allFish = await repository.getAll()
        XCTAssertEqual(allFish.count, 0)
    }

    func testInitializationFallsBackToEmptyDataOnDataLoaderError() async {
        let repository = makeRepository(loader: FakeDataLoader(mode: .error))

        let allFish = await repository.getAll()
        XCTAssertEqual(allFish.count, 0)
    }

    // MARK: - Fish Tier Tests

    func testFishTiersAreCorrect() async throws {
        let repository = makeRepository(loader: FakeDataLoader(mode: .valid))

        // Common (tier 4)
        let sunny = await repository.getById(id: TestFishID.sunny)
        let dewdrop = await repository.getById(id: TestFishID.dewdrop)
        let pebble = await repository.getById(id: TestFishID.pebble)
        let whisker = await repository.getById(id: TestFishID.whisker)
        XCTAssertEqual(sunny?.tier, .common)
        XCTAssertEqual(dewdrop?.tier, .common)
        XCTAssertEqual(pebble?.tier, .common)
        XCTAssertEqual(whisker?.tier, .common)

        // Uncommon (tier 3)
        let bristle = await repository.getById(id: TestFishID.bristle)
        let duskfin = await repository.getById(id: TestFishID.duskfin)
        let ember = await repository.getById(id: TestFishID.ember)
        XCTAssertEqual(bristle?.tier, .uncommon)
        XCTAssertEqual(duskfin?.tier, .uncommon)
        XCTAssertEqual(ember?.tier, .uncommon)

        // Rare (tier 2)
        let dancer = await repository.getById(id: TestFishID.dancer)
        let ribbontail = await repository.getById(id: TestFishID.ribbontail)
        XCTAssertEqual(dancer?.tier, .rare)
        XCTAssertEqual(ribbontail?.tier, .rare)

        // Legendary (tier 1)
        let streamer = await repository.getById(id: TestFishID.streamer)
        let swallowtail = await repository.getById(id: TestFishID.swallowtail)
        XCTAssertEqual(streamer?.tier, .legendary)
        XCTAssertEqual(swallowtail?.tier, .legendary)
    }
}

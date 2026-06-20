//
//  DungeonRunRewardsTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import XCTest
@testable import elf_Kit

/// Tests for the dungeon run reward ledger: material merging in `accrue`
/// (so repeated drops don't bloat the ledger) and the `Codable` round-trip
/// (the ledger is its own on-disk form — no parallel SaveData DTO).
final class DungeonRunRewardsTests: XCTestCase {

    // MARK: - accrue: material merging

    func testAccrue_MergesMaterialsBySameId() {
        let iron = MaterialID()
        let gold = MaterialID()
        var ledger = DungeonRunRewards.empty

        ledger.accrue(HuntRewards(
            experience: 10,
            materials: [MaterialReward(id: iron, amount: 2), MaterialReward(id: gold, amount: 1)]
        ))
        ledger.accrue(HuntRewards(
            experience: 5,
            materials: [MaterialReward(id: iron, amount: 3)]
        ))

        XCTAssertEqual(ledger.experience, 15)
        // iron merged into one entry (2 + 3), gold untouched — two entries total.
        XCTAssertEqual(ledger.materials.count, 2)
        XCTAssertEqual(ledger.materials.first { $0.id == iron }?.amount, 5)
        XCTAssertEqual(ledger.materials.first { $0.id == gold }?.amount, 1)
    }

    func testAccrue_DistinctMaterialIds_StaySeparate() {
        var ledger = DungeonRunRewards.empty
        ledger.accrue(HuntRewards(experience: 0, materials: [MaterialReward(id: MaterialID(), amount: 1)]))
        ledger.accrue(HuntRewards(experience: 0, materials: [MaterialReward(id: MaterialID(), amount: 1)]))

        XCTAssertEqual(ledger.materials.count, 2)
    }

    // MARK: - Codable round-trip (on-disk DTO)

    func testSaveData_CodableRoundTrip_PreservesAllFields() throws {
        let original = DungeonRunRewardsSaveData(
            experience: 42,
            materials: [
                MaterialReward(id: MaterialID(), amount: 7),
                MaterialReward(id: MaterialID(), amount: 1)
            ],
            weapons: [],
            armor: []
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DungeonRunRewardsSaveData.self, from: encoded)

        XCTAssertEqual(decoded, original)
    }

    func testEmpty_IsAllZeroOrEmpty() {
        let empty = DungeonRunRewards.empty
        XCTAssertEqual(empty.experience, 0)
        XCTAssertTrue(empty.materials.isEmpty)
        XCTAssertTrue(empty.weapons.isEmpty)
        XCTAssertTrue(empty.armor.isEmpty)
    }
}

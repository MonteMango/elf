//
//  RosterProgressionMutatorTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests the `RosterProgressionMutator` extracted from `GameSession`'s
/// Roster Progression MARK (T8): `addExperience`/`addDrops` (any elf) and
/// `addDropsToPlayerInventory` (Player Progression MARK, which routes into
/// `addDrops`). Exercised directly against the injected type (via
/// `@Dependency(\.rosterProgressionMutator)`), independent of `GameSession`.
final class RosterProgressionMutatorTests: XCTestCase {

    // MARK: - Fixture Builders

    private func makeWeaponItem(id: UUID = UUID()) -> WeaponItem {
        // swiftlint:disable:next force_try
        try! TestFixtures.weaponItem(
            id: id, title: "Test Sword", handUse: .oneHand,
            minimumAttackPoint: 5, maximumAttackPoint: 10,
            epBlockCost: 200
        )
    }

    private func makeWeapon() -> ElfWeaponItem {
        ElfWeaponItem(weaponItem: makeWeaponItem())
    }

    // MARK: - addExperience

    func testAddExperience_AddsAmountToCurrentExp() {
        let result = withDependencies {
            $0.inventoryService = ElfInventoryService()
        } operation: {
            @Dependency(\.rosterProgressionMutator) var mutator
            return mutator.addExperience(30, to: 20)
        }

        XCTAssertEqual(result, 50)
    }

    func testAddExperience_ZeroAmount_ReturnsCurrentExpUnchanged() {
        let result = withDependencies {
            $0.inventoryService = ElfInventoryService()
        } operation: {
            @Dependency(\.rosterProgressionMutator) var mutator
            return mutator.addExperience(0, to: 75)
        }

        XCTAssertEqual(result, 75)
    }

    // MARK: - addDrops

    func testAddDrops_AddsMaterialsAndWeaponsToInventory() {
        let materialId = MaterialID()
        let materials = [MaterialReward(id: materialId, amount: 3)]
        let weapon = makeWeapon()

        let updatedInventory = withDependencies {
            $0.inventoryService = ElfInventoryService()
        } operation: {
            @Dependency(\.rosterProgressionMutator) var mutator
            return mutator.addDrops(
                materials: materials,
                weapons: [weapon],
                armor: [],
                to: ElfInventory()
            )
        }

        XCTAssertEqual(updatedInventory.weapons.count, 1)
        XCTAssertEqual(
            updatedInventory.materials.first(where: { $0.ref == .monster(materialId) })?.quantity,
            3
        )
    }

    func testAddDrops_CalledTwice_StacksMaterialQuantityOnExistingInventory() {
        let materialId = MaterialID()
        let materials = [MaterialReward(id: materialId, amount: 2)]

        let updatedInventory = withDependencies {
            $0.inventoryService = ElfInventoryService()
        } operation: {
            @Dependency(\.rosterProgressionMutator) var mutator
            let first = mutator.addDrops(materials: materials, weapons: [], armor: [], to: ElfInventory())
            return mutator.addDrops(materials: materials, weapons: [], armor: [], to: first)
        }

        XCTAssertEqual(
            updatedInventory.materials.first(where: { $0.ref == .monster(materialId) })?.quantity,
            4
        )
    }
}

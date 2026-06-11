//
//  ElfEquipmentServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 25.04.26.
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for `ElfEquipmentService.equipWeapon(...)` and `equipOffhandWeapon(...)`.
/// Covers the slot-intent split introduced with the `WeaponHandUse.{primary,secondary}` → `.oneHand` merge:
/// `equipWeapon` always replaces the main hand; `equipOffhandWeapon` always targets the off-hand slot.
///
/// The service is a pure transform: each call takes the current `EquippedItems`
/// + source `ElfInventory` and returns a new `EquippedItems`. Tests assert on the
/// returned value directly — no `GameStore` involved.
final class ElfEquipmentServiceTests: XCTestCase {

    // MARK: - Fixture Builders

    private func makeWeaponItem(id: UUID = UUID(), handUse: WeaponHandUse) -> WeaponItem {
        // swiftlint:disable:next force_try
        return try! TestFixtures.weaponItem(
            id: id, handUse: handUse,
            minimumAttackPoint: 5, maximumAttackPoint: 10,
            epBlockCost: 200
        )
    }

    private func makeShieldItem(id: UUID = UUID()) -> ShieldItem {
        // swiftlint:disable:next force_try
        return try! TestFixtures.shieldItem(id: id, physicalDefensePoint: 2)
    }

    private func makeOneHanded(id: UUID = UUID()) -> (ElfWeaponItem, ElfOneHandedWeaponItem) {
        let item = makeWeaponItem(id: id, handUse: .oneHand)
        let elf = ElfWeaponItem(weaponItem: item)
        guard let oneHanded = ElfOneHandedWeaponItem(weapon: elf) else {
            fatalError("Fixture must produce a one-handed wrapper")
        }
        return (elf, oneHanded)
    }

    private func makeTwoHanded(id: UUID = UUID()) -> (ElfWeaponItem, ElfTwoHandedWeaponItem) {
        let item = makeWeaponItem(id: id, handUse: .both)
        let elf = ElfWeaponItem(weaponItem: item)
        guard let twoHanded = ElfTwoHandedWeaponItem(weapon: elf) else {
            fatalError("Fixture must produce a two-handed wrapper")
        }
        return (elf, twoHanded)
    }

    private func makeShield(id: UUID = UUID()) -> ElfShieldItem {
        ElfShieldItem(id: OwnedItemID(), item: makeShieldItem(id: id))
    }

    private func makeInventory(weapons: [ElfWeaponItem]) -> ElfInventory {
        var inventory = ElfInventory()
        inventory.weapons = weapons
        return inventory
    }

    /// `itemsRepository` is only consulted by `equipArmor`; weapon-slot tests
    /// resolve every item from the supplied `inventory`, so an empty fake suffices.
    private func makeService() -> ElfEquipmentService {
        withDependencies {
            $0.itemsRepository = FakeItemsRepository()
        } operation: {
            ElfEquipmentService()
        }
    }

    // MARK: - equipOffhandWeapon

    func testEquipOffhandWeapon_OneHanded_PromotesToDualWield() {
        let (existing, existingWrap) = makeOneHanded()
        let (newWeapon, _) = makeOneHanded()

        let result = makeService().equipOffhandWeapon(
            id: newWeapon.id,
            in: EquippedItems(weapons: .oneHanded(weapon: existingWrap)),
            inventory: makeInventory(weapons: [existing, newWeapon])
        )

        guard case let .dualWield(primary, secondary) = result.weapons else {
            return XCTFail("Expected dualWield")
        }
        XCTAssertEqual(primary.id, existing.id)
        XCTAssertEqual(secondary.id, newWeapon.id)
    }

    func testEquipOffhandWeapon_OneHandedWithShield_DropsShieldAndDualWields() {
        let (existing, existingWrap) = makeOneHanded()
        let shield = makeShield()
        let (newWeapon, _) = makeOneHanded()

        let result = makeService().equipOffhandWeapon(
            id: newWeapon.id,
            in: EquippedItems(weapons: .oneHandedWithShield(weapon: existingWrap, shield: shield)),
            inventory: makeInventory(weapons: [existing, newWeapon])
        )

        guard case let .dualWield(primary, secondary) = result.weapons else {
            return XCTFail("Expected dualWield (shield should have been dropped)")
        }
        XCTAssertEqual(primary.id, existing.id)
        XCTAssertEqual(secondary.id, newWeapon.id)
    }

    func testEquipOffhandWeapon_DualWield_ReplacesSecondary() {
        let (primary, primaryWrap) = makeOneHanded()
        let (oldSecondary, oldSecondaryWrap) = makeOneHanded()
        let (newSecondary, _) = makeOneHanded()

        let result = makeService().equipOffhandWeapon(
            id: newSecondary.id,
            in: EquippedItems(weapons: .dualWield(primary: primaryWrap, secondary: oldSecondaryWrap)),
            inventory: makeInventory(weapons: [primary, oldSecondary, newSecondary])
        )

        guard case let .dualWield(resultPrimary, resultSecondary) = result.weapons else {
            return XCTFail("Expected dualWield")
        }
        XCTAssertEqual(resultPrimary.id, primary.id)
        XCTAssertEqual(resultSecondary.id, newSecondary.id)
    }

    func testEquipOffhandWeapon_TwoHanded_PromotesToOneHanded() {
        let (existing, existingWrap) = makeTwoHanded()
        let (newWeapon, _) = makeOneHanded()

        let result = makeService().equipOffhandWeapon(
            id: newWeapon.id,
            in: EquippedItems(weapons: .twoHanded(weapon: existingWrap)),
            inventory: makeInventory(weapons: [existing, newWeapon])
        )

        guard case let .oneHanded(weapon) = result.weapons else {
            return XCTFail("Expected oneHanded (twoHanded should have been replaced)")
        }
        XCTAssertEqual(weapon.id, newWeapon.id)
    }

    func testEquipOffhandWeapon_TwoHandedWeaponInput_NoOp() {
        let (existing, existingWrap) = makeOneHanded()
        let (twoHandedInput, _) = makeTwoHanded()

        let result = makeService().equipOffhandWeapon(
            id: twoHandedInput.id,
            in: EquippedItems(weapons: .oneHanded(weapon: existingWrap)),
            inventory: makeInventory(weapons: [existing, twoHandedInput])
        )

        guard case let .oneHanded(weapon) = result.weapons else {
            return XCTFail("State should be unchanged")
        }
        XCTAssertEqual(weapon.id, existing.id)
    }

    // MARK: - equipWeapon

    func testEquipWeapon_OneHanded_AutoPromotesToDualWield() {
        let (existing, existingWrap) = makeOneHanded()
        let (newWeapon, _) = makeOneHanded()

        let result = makeService().equipWeapon(
            id: newWeapon.id,
            in: EquippedItems(weapons: .oneHanded(weapon: existingWrap)),
            inventory: makeInventory(weapons: [existing, newWeapon])
        )

        guard case let .dualWield(primary, secondary) = result.weapons else {
            return XCTFail("Expected dualWield (second one-hander should fill the off-hand slot)")
        }
        XCTAssertEqual(primary.id, existing.id)
        XCTAssertEqual(secondary.id, newWeapon.id)
    }

    func testEquipWeapon_OneHanded_DualWield_PreservesSecondary() {
        let (oldPrimary, oldPrimaryWrap) = makeOneHanded()
        let (secondary, secondaryWrap) = makeOneHanded()
        let (newPrimary, _) = makeOneHanded()

        let result = makeService().equipWeapon(
            id: newPrimary.id,
            in: EquippedItems(weapons: .dualWield(primary: oldPrimaryWrap, secondary: secondaryWrap)),
            inventory: makeInventory(weapons: [oldPrimary, secondary, newPrimary])
        )

        guard case let .dualWield(resultPrimary, resultSecondary) = result.weapons else {
            return XCTFail("Expected dualWield (secondary should have been preserved)")
        }
        XCTAssertEqual(resultPrimary.id, newPrimary.id)
        XCTAssertEqual(resultSecondary.id, secondary.id)
    }
}

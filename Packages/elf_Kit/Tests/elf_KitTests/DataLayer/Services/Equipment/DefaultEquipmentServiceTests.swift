//
//  DefaultEquipmentServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 25.04.26.
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for `DefaultEquipmentService.equipWeapon(id:)` and `equipOffhandWeapon(id:)`.
/// Covers the slot-intent split introduced with the `WeaponHandUse.{primary,secondary}` → `.oneHand` merge:
/// `equipWeapon` always replaces the main hand; `equipOffhandWeapon` always targets the off-hand slot.
@MainActor
final class DefaultEquipmentServiceTests: XCTestCase {

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

    private func makeElf(
        equipped: EquippedItems,
        inventoryWeapons: [ElfWeaponItem]
    ) -> ElfInfo {
        var inventory = ElfInventory()
        inventory.weapons = inventoryWeapons
        let attrs = HeroAttributes(hitPoints: 80, manaPoints: 20, agility: 1, strength: 1, power: 1, instinct: 1, endurance: 0)
        return ElfInfo(
            name: "Tester",
            imageName: "elf_1",
            fightStyle: .dodge,
            currentExp: 0,
            fightStyleAttributes: attrs,
            randomLevelAttributes: HeroAttributes(),
            equipped: equipped,
            inventory: inventory
        )
    }

    private func makeGame(player: ElfInfo) -> Game {
        let aiMember = makeElf(
            equipped: EquippedItems(weapons: .twoHanded(weapon: makeTwoHanded().1)),
            inventoryWeapons: []
        )
        let members = [player] + Array(repeating: aiMember, count: House.membersCount - 1)
        let houses: [House] = (0..<Game.housesCount).map { i in
            House(name: "H\(i)", logoImageName: "logo", members: members)
        }
        let calendar = [GameDay(dayNumber: 1, dayType: .normal)]
        let gameState = GameState(
            currentDay: calendar[0],
            actionPoints: ActionPoints.unsafeCreate(current: 100, maximum: 100),
            calendar: calendar
        )
        return Game(
            houses: houses,
            gameState: gameState,
            playerHouseIndex: 0,
            playerMemberIndex: 0
        )
    }

    private func makeService(
        equipped: EquippedItems,
        inventoryWeapons: [ElfWeaponItem],
        repository: FakeItemsRepository
    ) -> (DefaultEquipmentService, GameStore) {
        let player = makeElf(equipped: equipped, inventoryWeapons: inventoryWeapons)
        let game = makeGame(player: player)
        let store = GameStore(from: game)
        let service = withDependencies {
            $0.itemsRepository = repository
        } operation: {
            DefaultEquipmentService(store: store)
        }
        return (service, store)
    }

    // MARK: - equipOffhandWeapon

    func testEquipOffhandWeapon_OneHanded_PromotesToDualWield() {
        let (existing, existingWrap) = makeOneHanded()
        let (newWeapon, _) = makeOneHanded()

        let repository = FakeItemsRepository()
        repository.items[newWeapon.item.id] = newWeapon.item
        let (service, store) = makeService(
            equipped: EquippedItems(weapons: .oneHanded(weapon: existingWrap)),
            inventoryWeapons: [existing, newWeapon],
            repository: repository
        )

        service.equipOffhandWeapon(id: newWeapon.id)

        guard case let .dualWield(primary, secondary) = store.player.equipped.weapons else {
            return XCTFail("Expected dualWield")
        }
        XCTAssertEqual(primary.id, existing.id)
        XCTAssertEqual(secondary.id, newWeapon.id)
    }

    func testEquipOffhandWeapon_OneHandedWithShield_DropsShieldAndDualWields() {
        let (existing, existingWrap) = makeOneHanded()
        let shield = makeShield()
        let (newWeapon, _) = makeOneHanded()

        let repository = FakeItemsRepository()
        repository.items[newWeapon.item.id] = newWeapon.item
        let (service, store) = makeService(
            equipped: EquippedItems(weapons: .oneHandedWithShield(weapon: existingWrap, shield: shield)),
            inventoryWeapons: [existing, newWeapon],
            repository: repository
        )

        service.equipOffhandWeapon(id: newWeapon.id)

        guard case let .dualWield(primary, secondary) = store.player.equipped.weapons else {
            return XCTFail("Expected dualWield (shield should have been dropped)")
        }
        XCTAssertEqual(primary.id, existing.id)
        XCTAssertEqual(secondary.id, newWeapon.id)
    }

    func testEquipOffhandWeapon_DualWield_ReplacesSecondary() {
        let (primary, primaryWrap) = makeOneHanded()
        let (oldSecondary, oldSecondaryWrap) = makeOneHanded()
        let (newSecondary, _) = makeOneHanded()

        let repository = FakeItemsRepository()
        repository.items[newSecondary.item.id] = newSecondary.item
        let (service, store) = makeService(
            equipped: EquippedItems(weapons: .dualWield(primary: primaryWrap, secondary: oldSecondaryWrap)),
            inventoryWeapons: [primary, oldSecondary, newSecondary],
            repository: repository
        )

        service.equipOffhandWeapon(id: newSecondary.id)

        guard case let .dualWield(resultPrimary, resultSecondary) = store.player.equipped.weapons else {
            return XCTFail("Expected dualWield")
        }
        XCTAssertEqual(resultPrimary.id, primary.id)
        XCTAssertEqual(resultSecondary.id, newSecondary.id)
    }

    func testEquipOffhandWeapon_TwoHanded_PromotesToOneHanded() {
        let (existing, existingWrap) = makeTwoHanded()
        let (newWeapon, _) = makeOneHanded()

        let repository = FakeItemsRepository()
        repository.items[newWeapon.item.id] = newWeapon.item
        let (service, store) = makeService(
            equipped: EquippedItems(weapons: .twoHanded(weapon: existingWrap)),
            inventoryWeapons: [existing, newWeapon],
            repository: repository
        )

        service.equipOffhandWeapon(id: newWeapon.id)

        guard case let .oneHanded(weapon) = store.player.equipped.weapons else {
            return XCTFail("Expected oneHanded (twoHanded should have been replaced)")
        }
        XCTAssertEqual(weapon.id, newWeapon.id)
    }

    func testEquipOffhandWeapon_TwoHandedWeaponInput_NoOp() {
        let (existing, existingWrap) = makeOneHanded()
        let (twoHandedInput, _) = makeTwoHanded()

        let repository = FakeItemsRepository()
        repository.items[twoHandedInput.item.id] = twoHandedInput.item
        let (service, store) = makeService(
            equipped: EquippedItems(weapons: .oneHanded(weapon: existingWrap)),
            inventoryWeapons: [existing, twoHandedInput],
            repository: repository
        )

        service.equipOffhandWeapon(id: twoHandedInput.id)

        guard case let .oneHanded(weapon) = store.player.equipped.weapons else {
            return XCTFail("State should be unchanged")
        }
        XCTAssertEqual(weapon.id, existing.id)
    }

    // MARK: - equipWeapon

    func testEquipWeapon_OneHanded_AutoPromotesToDualWield() {
        let (existing, existingWrap) = makeOneHanded()
        let (newWeapon, _) = makeOneHanded()

        let repository = FakeItemsRepository()
        repository.items[newWeapon.item.id] = newWeapon.item
        let (service, store) = makeService(
            equipped: EquippedItems(weapons: .oneHanded(weapon: existingWrap)),
            inventoryWeapons: [existing, newWeapon],
            repository: repository
        )

        service.equipWeapon(id: newWeapon.id)

        guard case let .dualWield(primary, secondary) = store.player.equipped.weapons else {
            return XCTFail("Expected dualWield (second one-hander should fill the off-hand slot)")
        }
        XCTAssertEqual(primary.id, existing.id)
        XCTAssertEqual(secondary.id, newWeapon.id)
    }

    func testEquipWeapon_OneHanded_DualWield_PreservesSecondary() {
        let (oldPrimary, oldPrimaryWrap) = makeOneHanded()
        let (secondary, secondaryWrap) = makeOneHanded()
        let (newPrimary, _) = makeOneHanded()

        let repository = FakeItemsRepository()
        repository.items[newPrimary.item.id] = newPrimary.item
        let (service, store) = makeService(
            equipped: EquippedItems(weapons: .dualWield(primary: oldPrimaryWrap, secondary: secondaryWrap)),
            inventoryWeapons: [oldPrimary, secondary, newPrimary],
            repository: repository
        )

        service.equipWeapon(id: newPrimary.id)

        guard case let .dualWield(resultPrimary, resultSecondary) = store.player.equipped.weapons else {
            return XCTFail("Expected dualWield (secondary should have been preserved)")
        }
        XCTAssertEqual(resultPrimary.id, newPrimary.id)
        XCTAssertEqual(resultSecondary.id, secondary.id)
    }
}

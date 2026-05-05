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

    // MARK: - Fakes

    final class FakeItemsRepository: ItemsRepository {
        nonisolated(unsafe) var items: [UUID: Item] = [:]

        func getHeroItem(_ id: UUID) -> Item? { items[id] }
        func getItems(for type: HeroItemType) -> [Item] { [] }
        func armorSlot(for itemId: UUID) -> ArmorSlot? { nil }
    }

    // MARK: - Fixture Builders

    private func makeWeaponItem(id: UUID = UUID(), handUse: WeaponHandUse) -> WeaponItem {
        let json = """
        {
            "id": "\(id.uuidString)",
            "title": "Test Weapon",
            "tier": 1,
            "minimumAttackPoint": 5,
            "maximumAttackPoint": 10,
            "handUse": "\(handUse.rawValue)"
        }
        """
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(WeaponItem.self, from: Data(json.utf8))
    }

    private func makeShieldItem(id: UUID = UUID()) -> ShieldItem {
        let json = """
        {
            "id": "\(id.uuidString)",
            "title": "Test Shield",
            "tier": 1,
            "physicalDefensePoint": 2
        }
        """
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(ShieldItem.self, from: Data(json.utf8))
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
        ElfShieldItem(id: UUID(), item: makeShieldItem(id: id))
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
            currentHP: 80,
            currentMP: 20,
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
    ) -> (DefaultEquipmentService, DefaultGameService) {
        let player = makeElf(equipped: equipped, inventoryWeapons: inventoryWeapons)
        let game = makeGame(player: player)
        let gameService = DefaultGameService(game: game)
        let service = withDependencies {
            $0.itemsRepository = repository
        } operation: {
            DefaultEquipmentService(gameService: gameService)
        }
        return (service, gameService)
    }

    // MARK: - equipOffhandWeapon

    func testEquipOffhandWeapon_OneHanded_PromotesToDualWield() {
        let (existing, existingWrap) = makeOneHanded()
        let (newWeapon, _) = makeOneHanded()

        let repository = FakeItemsRepository()
        repository.items[newWeapon.id] = newWeapon.item
        let (service, gameService) = makeService(
            equipped: EquippedItems(weapons: .oneHanded(weapon: existingWrap)),
            inventoryWeapons: [existing, newWeapon],
            repository: repository
        )

        service.equipOffhandWeapon(id: newWeapon.id)

        guard case let .dualWield(primary, secondary) = gameService.player.equipped.weapons else {
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
        repository.items[newWeapon.id] = newWeapon.item
        let (service, gameService) = makeService(
            equipped: EquippedItems(weapons: .oneHandedWithShield(weapon: existingWrap, shield: shield)),
            inventoryWeapons: [existing, newWeapon],
            repository: repository
        )

        service.equipOffhandWeapon(id: newWeapon.id)

        guard case let .dualWield(primary, secondary) = gameService.player.equipped.weapons else {
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
        repository.items[newSecondary.id] = newSecondary.item
        let (service, gameService) = makeService(
            equipped: EquippedItems(weapons: .dualWield(primary: primaryWrap, secondary: oldSecondaryWrap)),
            inventoryWeapons: [primary, oldSecondary, newSecondary],
            repository: repository
        )

        service.equipOffhandWeapon(id: newSecondary.id)

        guard case let .dualWield(resultPrimary, resultSecondary) = gameService.player.equipped.weapons else {
            return XCTFail("Expected dualWield")
        }
        XCTAssertEqual(resultPrimary.id, primary.id)
        XCTAssertEqual(resultSecondary.id, newSecondary.id)
    }

    func testEquipOffhandWeapon_TwoHanded_PromotesToOneHanded() {
        let (existing, existingWrap) = makeTwoHanded()
        let (newWeapon, _) = makeOneHanded()

        let repository = FakeItemsRepository()
        repository.items[newWeapon.id] = newWeapon.item
        let (service, gameService) = makeService(
            equipped: EquippedItems(weapons: .twoHanded(weapon: existingWrap)),
            inventoryWeapons: [existing, newWeapon],
            repository: repository
        )

        service.equipOffhandWeapon(id: newWeapon.id)

        guard case let .oneHanded(weapon) = gameService.player.equipped.weapons else {
            return XCTFail("Expected oneHanded (twoHanded should have been replaced)")
        }
        XCTAssertEqual(weapon.id, newWeapon.id)
    }

    func testEquipOffhandWeapon_TwoHandedWeaponInput_NoOp() {
        let (existing, existingWrap) = makeOneHanded()
        let (twoHandedInput, _) = makeTwoHanded()

        let repository = FakeItemsRepository()
        repository.items[twoHandedInput.id] = twoHandedInput.item
        let (service, gameService) = makeService(
            equipped: EquippedItems(weapons: .oneHanded(weapon: existingWrap)),
            inventoryWeapons: [existing, twoHandedInput],
            repository: repository
        )

        service.equipOffhandWeapon(id: twoHandedInput.id)

        guard case let .oneHanded(weapon) = gameService.player.equipped.weapons else {
            return XCTFail("State should be unchanged")
        }
        XCTAssertEqual(weapon.id, existing.id)
    }

    // MARK: - equipWeapon

    func testEquipWeapon_OneHanded_AutoPromotesToDualWield() {
        let (existing, existingWrap) = makeOneHanded()
        let (newWeapon, _) = makeOneHanded()

        let repository = FakeItemsRepository()
        repository.items[newWeapon.id] = newWeapon.item
        let (service, gameService) = makeService(
            equipped: EquippedItems(weapons: .oneHanded(weapon: existingWrap)),
            inventoryWeapons: [existing, newWeapon],
            repository: repository
        )

        service.equipWeapon(id: newWeapon.id)

        guard case let .dualWield(primary, secondary) = gameService.player.equipped.weapons else {
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
        repository.items[newPrimary.id] = newPrimary.item
        let (service, gameService) = makeService(
            equipped: EquippedItems(weapons: .dualWield(primary: oldPrimaryWrap, secondary: secondaryWrap)),
            inventoryWeapons: [oldPrimary, secondary, newPrimary],
            repository: repository
        )

        service.equipWeapon(id: newPrimary.id)

        guard case let .dualWield(resultPrimary, resultSecondary) = gameService.player.equipped.weapons else {
            return XCTFail("Expected dualWield (secondary should have been preserved)")
        }
        XCTAssertEqual(resultPrimary.id, newPrimary.id)
        XCTAssertEqual(resultSecondary.id, secondary.id)
    }
}

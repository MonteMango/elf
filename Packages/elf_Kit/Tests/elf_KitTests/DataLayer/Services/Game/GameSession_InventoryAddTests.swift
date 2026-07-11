//
//  GameSession_InventoryAddTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for `GameSession.addFishToInventory(_:)` / `addHerbsToInventory(_:)` /
/// `addOresToInventory(_:)`.
///
/// DUP-1 (see `docs/features/architecture-hardening/tasks/t6-dup1-inventory-add-collapse.md`)
/// collapses the three near-identical `map` + `addMaterials(...)` transforms into
/// one core add path inside `GameSession`, keeping each public method as a thin
/// typed shim with its original signature. These tests pin the observable
/// behaviour (each shim adds exactly one `InventoryMaterial` per gathered item,
/// tagged with the matching `MaterialRef` case) so the collapse can't silently
/// change what callers observe.
@MainActor
final class GameSession_InventoryAddTests: XCTestCase {

    /// `GameSession` pulls the inventory service via `@Dependency`. Wire the real
    /// stateless implementation so every test exercises the actual add path.
    override func invokeTest() {
        withDependencies {
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
        } operation: {
            super.invokeTest()
        }
    }

    // MARK: - Fixture Builders

    private func makeWeaponItem(id: UUID = UUID()) -> WeaponItem {
        // swiftlint:disable:next force_try
        return try! TestFixtures.weaponItem(
            id: id, title: "Test Sword", handUse: .oneHand,
            minimumAttackPoint: 5, maximumAttackPoint: 10,
            epBlockCost: 200
        )
    }

    private func makeElf(inventory: ElfInventory = ElfInventory()) -> ElfInfo {
        let attrs = HeroAttributes(hitPoints: 80, manaPoints: 20, agility: 1, strength: 1, power: 1, instinct: 1, endurance: 0)
        let weapon = ElfWeaponItem(weaponItem: makeWeaponItem())
        guard let oneHanded = ElfOneHandedWeaponItem(weapon: weapon) else {
            fatalError("Test fixture weapon must be one-handed")
        }
        return ElfInfo(
            name: "Tester",
            imageName: "elf_1",
            fightStyle: .dodge,
            currentExp: 0,
            fightStyleAttributes: attrs,
            randomLevelAttributes: HeroAttributes(),
            equipped: EquippedItems(weapons: .oneHanded(weapon: oneHanded)),
            inventory: inventory
        )
    }

    private func makeGame() -> Game {
        let player = makeElf()
        let members = [player] + (0..<(House.membersCount - 1)).map { _ in makeElf() }
        let houses: [House] = (0..<Game.housesCount).map { i in
            House(name: "H\(i)", logoImageName: "logo", members: members)
        }
        let calendar = [GameDay(dayNumber: 1, dayType: .normal)]
        let gameState = GameState(currentDay: calendar[0], calendar: calendar)
        return Game(
            houses: houses,
            gameState: gameState,
            playerHouseIndex: 0,
            playerMemberIndex: 0
        )
    }

    private func makeSession() -> (GameSession, GameStore) {
        let session = GameSession(game: makeGame())
        return (session, session.state)
    }

    private func makeFish(id: FishID = FishID()) -> Fish {
        Fish(id: id, title: "Test Fish", imageName: "fish", description: "", tier: .common, baseCatchChance: 0.5, effects: [])
    }

    private func makeHerb(id: HerbID = HerbID()) -> Herb {
        Herb(id: id, title: "Test Herb", imageName: "herb", description: "", tier: .common, baseGatherChance: 0.5, effects: [])
    }

    private func makeOre(id: OreID = OreID()) -> Ore {
        Ore(id: id, title: "Test Ore", imageName: "ore", description: "", tier: .common, baseMineChance: 0.5, effects: [])
    }

    // MARK: - addFishToInventory

    func testAddFishToInventory_AddsOneMaterialPerFish_TaggedAsFish() {
        // Given
        let (session, store) = makeSession()
        let fishA = makeFish()
        let fishB = makeFish()

        // When
        session.addFishToInventory([fishA, fishB])

        // Then
        let materials = store.player.inventory.materials
        XCTAssertEqual(materials.count, 2)
        XCTAssertEqual(materials.first(where: { $0.ref == .fish(fishA.id) })?.quantity, 1)
        XCTAssertEqual(materials.first(where: { $0.ref == .fish(fishB.id) })?.quantity, 1)
    }

    // MARK: - addHerbsToInventory

    func testAddHerbsToInventory_AddsOneMaterialPerHerb_TaggedAsHerb() {
        // Given
        let (session, store) = makeSession()
        let herb = makeHerb()

        // When
        session.addHerbsToInventory([herb])

        // Then
        let materials = store.player.inventory.materials
        XCTAssertEqual(materials.count, 1)
        XCTAssertEqual(materials.first?.ref, .herb(herb.id))
        XCTAssertEqual(materials.first?.quantity, 1)
    }

    // MARK: - addOresToInventory

    func testAddOresToInventory_AddsOneMaterialPerOre_TaggedAsOre() {
        // Given
        let (session, store) = makeSession()
        let ore = makeOre()

        // When
        session.addOresToInventory([ore])

        // Then
        let materials = store.player.inventory.materials
        XCTAssertEqual(materials.count, 1)
        XCTAssertEqual(materials.first?.ref, .ore(ore.id))
        XCTAssertEqual(materials.first?.quantity, 1)
    }

    // MARK: - Stacking across repeated calls (core-path invariant)

    func testAddFishToInventory_CalledTwice_StacksQuantityOnSameCore() {
        // Given
        let (session, store) = makeSession()
        let fish = makeFish()

        // When
        session.addFishToInventory([fish])
        session.addFishToInventory([fish])

        // Then
        let materials = store.player.inventory.materials
        XCTAssertEqual(materials.count, 1)
        XCTAssertEqual(materials.first(where: { $0.ref == .fish(fish.id) })?.quantity, 2)
    }
}

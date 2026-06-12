//
//  GameSession_CraftTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for `GameSession.craftItem(recipe:item:)`.
///
/// Covers the atomic craft transaction (validate → deduct → add) that replaced
/// the former `modifyInventory` closure escape hatch used by `CraftViewModel`.
@MainActor
final class GameSession_CraftTests: XCTestCase {

    /// `GameSession` pulls craft/inventory services via `@Dependency`.
    /// Wire the real stateless implementations so every test exercises the actual
    /// craft transaction without each one spelling out `withDependencies`.
    override func invokeTest() {
        withDependencies {
            $0.craftService = DefaultCraftService()
            $0.inventoryService = ElfInventoryService()
        } operation: {
            super.invokeTest()
        }
    }

    // MARK: - Fakes

    private struct NoOpStorage: GameSaveStorage {
        func save(_ game: Game, slotId: String, playTime: TimeInterval) async throws {}
        func load(slotId: String) async throws -> Game { fatalError("unused") }
        func hasAnySave() -> Bool { false }
        func getPlayTime(slotId: String) async -> TimeInterval { 0 }
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
        // The fixture weapon has `handUse: "oneHand"` so it must be wrapped as a one-handed weapon
        // (the old code mistakenly put it in `.twoHanded`, which the type system now forbids).
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

    private func makeGame(playerInventory: ElfInventory = ElfInventory()) -> Game {
        let player = makeElf(inventory: playerInventory)
        let aiMember = makeElf()
        let members = [player] + Array(repeating: aiMember, count: House.membersCount - 1)

        let houses: [House] = (0..<Game.housesCount).map { i in
            House(name: "H\(i)", logoImageName: "logo", members: members)
        }

        let calendar = [GameDay(dayNumber: 1, dayType: .normal)]
        let gameState = GameState(
            currentDay: calendar[0],
            calendar: calendar
        )
        return Game(
            houses: houses,
            gameState: gameState,
            playerHouseIndex: 0,
            playerMemberIndex: 0
        )
    }

    private func makeSession(inventory: ElfInventory = ElfInventory()) -> (GameSession, GameStore) {
        let session = GameSession(game: makeGame(playerInventory: inventory))
        return (session, session.state)
    }

    private func makeRecipe(
        resultItemId: ItemID = ItemID(),
        ingredientId: UUID,
        amount: Int
    ) -> Recipe {
        Recipe(
            id: RecipeID(),
            resultItemId: resultItemId,
            category: .weapon,
            ingredients: [
                RecipeIngredient(itemId: ingredientId, type: .material, amount: amount)
            ]
        )
    }

    // MARK: - Success Cases

    func testCraftItem_WithSufficientMaterials_ReturnsTrue_AndDeductsMaterials_AndAddsItem() {
        // Given
        let materialId = UUID()
        var inventory = ElfInventory()
        inventory.materials.append(InventoryMaterial(ref: .monster(MaterialID(rawValue: materialId)), quantity: 5))
        let (session, store) = makeSession(inventory: inventory)

        let item = makeWeaponItem()
        let recipe = makeRecipe(resultItemId: item.id, ingredientId: materialId, amount: 3)

        // When
        let result = session.craftItem(recipe: recipe, item: item)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(store.player.inventory.materials.first(where: { $0.ref.rawValue == materialId })?.quantity, 2)
        XCTAssertEqual(store.player.inventory.weapons.count, 1)
    }

    func testCraftItem_WithExactMatch_RemovesEmptyMaterialStack() {
        // Given
        let materialId = UUID()
        var inventory = ElfInventory()
        inventory.materials.append(InventoryMaterial(ref: .monster(MaterialID(rawValue: materialId)), quantity: 3))
        let (session, store) = makeSession(inventory: inventory)

        let item = makeWeaponItem()
        let recipe = makeRecipe(resultItemId: item.id, ingredientId: materialId, amount: 3)

        // When
        let result = session.craftItem(recipe: recipe, item: item)

        // Then
        XCTAssertTrue(result)
        XCTAssertNil(store.player.inventory.materials.first(where: { $0.ref.rawValue == materialId }))
        XCTAssertEqual(store.player.inventory.weapons.count, 1)
    }

    // MARK: - Failure Cases

    func testCraftItem_WithInsufficientMaterials_ReturnsFalse_AndLeavesInventoryUnchanged() {
        // Given
        let materialId = UUID()
        var inventory = ElfInventory()
        inventory.materials.append(InventoryMaterial(ref: .monster(MaterialID(rawValue: materialId)), quantity: 2))
        let (session, store) = makeSession(inventory: inventory)

        let item = makeWeaponItem()
        let recipe = makeRecipe(resultItemId: item.id, ingredientId: materialId, amount: 3)

        // When
        let result = session.craftItem(recipe: recipe, item: item)

        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(store.player.inventory.materials.first(where: { $0.ref.rawValue == materialId })?.quantity, 2)
        XCTAssertEqual(store.player.inventory.weapons.count, 0)
    }

    func testCraftItem_WithMissingMaterial_ReturnsFalse_AndLeavesInventoryUnchanged() {
        // Given: empty inventory, recipe needs some material
        let (session, store) = makeSession()
        let item = makeWeaponItem()
        let recipe = makeRecipe(ingredientId: UUID(), amount: 1)

        // When
        let result = session.craftItem(recipe: recipe, item: item)

        // Then
        XCTAssertFalse(result)
        XCTAssertTrue(store.player.inventory.materials.isEmpty)
        XCTAssertTrue(store.player.inventory.weapons.isEmpty)
    }
}

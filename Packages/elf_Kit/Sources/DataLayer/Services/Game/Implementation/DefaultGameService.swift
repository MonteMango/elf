//
//  DefaultGameService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import Dependencies
import Foundation
import Observation

/// Default mutation service. Operates on a `GameStore` reference — mutations
/// are sync on the main thread, observation on `store.X` notifies SwiftUI.
/// Hidden behind `GameSession`; not constructed by views directly.
@MainActor
@Observable
public final class DefaultGameService: GameService {

    // MARK: - Dependencies

    private let store: GameStore
    private let inventoryService: any InventoryService
    private let craftService: any CraftService

    // MARK: - Initialization

    public init(store: GameStore) {
        @Dependency(\.inventoryService) var inventoryService
        @Dependency(\.craftService) var craftService
        self.inventoryService = inventoryService
        self.craftService = craftService
        self.store = store
    }

    // MARK: - Day Management

    public func advanceToNextDay() {
        let nextDayNumber = store.currentDay.dayNumber + 1
        guard let nextDayIndex = store.calendar.firstIndex(where: { $0.dayNumber == nextDayNumber }) else {
            return // No more days (game finished)
        }
        store.currentDay = store.calendar[nextDayIndex]
        store.actionPoints = store.actionPoints.reset()
    }

    public func spendActionPoints(_ amount: Int) {
        if case .success(let newPoints) = store.actionPoints.spend(amount) {
            store.actionPoints = newPoints
        }
    }

    // MARK: - Player Progression

    public func addPlayerExperience(_ amount: Int) {
        store.player.currentExp += amount
    }

    public func addFishingExperience(_ amount: Int) {
        store.player.fishingExp += amount
    }

    public func addForagingExperience(_ amount: Int) {
        store.player.foragingExp += amount
    }

    public func addMiningExperience(_ amount: Int) {
        store.player.miningExp += amount
    }

    public func addDropsToPlayerInventory(rewards: HuntRewards) {
        let additions = rewards.materials.map {
            MaterialAddition(id: $0.id, source: .monster, quantity: $0.amount)
        }
        var inventory = inventoryService.addMaterials(additions, to: store.player.inventory)
        if let weapon = rewards.weapon {
            inventory = inventoryService.addWeapon(weapon, to: inventory)
        }
        if let armor = rewards.armor {
            inventory = inventoryService.addArmor(armor, to: inventory)
        }
        store.player.inventory = inventory
    }

    public func addFishToInventory(_ fish: [Fish]) {
        let additions = fish.map {
            MaterialAddition(id: $0.id.rawValue, source: .fish, quantity: 1)
        }
        store.player.inventory = inventoryService.addMaterials(additions, to: store.player.inventory)
    }

    public func addHerbsToInventory(_ herbs: [Herb]) {
        let additions = herbs.map {
            MaterialAddition(id: $0.id.rawValue, source: .herb, quantity: 1)
        }
        store.player.inventory = inventoryService.addMaterials(additions, to: store.player.inventory)
    }

    public func addOresToInventory(_ ores: [Ore]) {
        let additions = ores.map {
            MaterialAddition(id: $0.id.rawValue, source: .ore, quantity: 1)
        }
        store.player.inventory = inventoryService.addMaterials(additions, to: store.player.inventory)
    }

    public func addItemsToPlayerInventory(_ items: [Item]) {
        var inventory = store.player.inventory
        for item in items {
            inventory = inventoryService.addCraftedItem(item, to: inventory)
        }
        store.player.inventory = inventory
    }

    // MARK: - Crafting

    /// Atomically validates, deducts materials, and adds the crafted item to inventory.
    /// Returns `true` on success, `false` if materials are insufficient.
    @discardableResult
    public func craftItem(recipe: Recipe, item: Item) -> Bool {
        var inventory = store.player.inventory
        guard craftService.canCraft(recipe: recipe, inventory: inventory) else { return false }
        inventory = craftService.deductMaterials(recipe: recipe, from: inventory)
        inventory = inventoryService.addCraftedItem(item, to: inventory)
        store.player.inventory = inventory
        return true
    }
}

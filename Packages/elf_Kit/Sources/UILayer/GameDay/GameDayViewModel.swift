//
//  GameDayViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import Foundation

@MainActor
@Observable
public final class GameDayViewModel {

    // MARK: - Dependencies

    private let gameService: any GameService
    private let progressionService: any ProgressionService
    private let equipmentQueryService: any EquipmentQueryService
    private let itemsRepository: any ItemsRepository

    // MARK: - Local UI State

    public var activeBuffs: [String] = []
    public var isInventoryVisible: Bool = false

    /// Item ID to pre-select when inventory opens
    public var pendingInventoryItemId: UUID?

    // MARK: - Derived state (computed reactively)

    public var player: PlayerStore { gameService.player }

    public var characterLevel: Int {
        progressionService.calculateLevel(currentExp: gameService.player.currentExp)
    }
    public var expToNextLevel: Int {
        progressionService.expToNextLevel(currentExp: gameService.player.currentExp)
    }
    public var xpProgress: Double {
        progressionService.expProgress(currentExp: gameService.player.currentExp)
    }
    public var equippedItems: [HeroItemType: UUID] {
        equipmentQueryService.equippedBaseItemIds(from: gameService.player.equipped)
    }

    // MARK: - Initialization

    public init(
        gameService: any GameService,
        progressionService: any ProgressionService,
        equipmentQueryService: any EquipmentQueryService,
        itemsRepository: any ItemsRepository
    ) {
        self.gameService = gameService
        self.progressionService = progressionService
        self.equipmentQueryService = equipmentQueryService
        self.itemsRepository = itemsRepository
    }

    // MARK: - Actions

    /// Called when an action button is tapped (non-navigation actions only)
    public func onActionTapped(_ action: ActionType) {
        print("Action tapped: \(action.rawValue)")
    }

    /// Called when a side menu button is tapped
    public func onSideMenuTapped(_ menu: SideMenuType) {
        switch menu {
        case .items:
            isInventoryVisible.toggle()
        case .house:
            fillEquipmentInventory()
        default:
            print("Side menu tapped: \(menu.rawValue)")
        }
    }

    /// Dev shortcut: ensure the player's inventory contains every weapon and armor piece defined in the game.
    /// One-handed weapons (handUse `.primary` / `.secondary`) top up to two copies; two-handed (`.both`)
    /// and each armor slot top up to one. Copies already present (matched by base item id) are preserved.
    private func fillEquipmentInventory() {
        var toAdd: [Item] = []
        toAdd.append(contentsOf: missingWeapons())
        toAdd.append(contentsOf: missingArmor())
        gameService.addItemsToPlayerInventory(toAdd)
    }

    private func missingWeapons() -> [Item] {
        let allWeapons = itemsRepository.getItems(for: .weapons).compactMap { $0 as? WeaponItem }
        let existingCountByItemId = gameService.player.inventory.weapons
            .reduce(into: [UUID: Int]()) { counts, weapon in counts[weapon.item.id, default: 0] += 1 }

        var toAdd: [Item] = []
        for weapon in allWeapons {
            let desiredCount = weapon.handUse == .both ? 1 : 2
            let missing = desiredCount - (existingCountByItemId[weapon.id] ?? 0)
            if missing > 0 {
                toAdd.append(contentsOf: Array(repeating: weapon as Item, count: missing))
            }
        }
        return toAdd
    }

    private func missingArmor() -> [Item] {
        let armorSlots: [HeroItemType] = [.helmet, .gloves, .shoes, .upperBody, .bottomBody]
        let existingItemIds = Set(gameService.player.inventory.armor.map { $0.item.id })

        var toAdd: [Item] = []
        for slot in armorSlots {
            for item in itemsRepository.getItems(for: slot) where !existingItemIds.contains(item.id) {
                toAdd.append(item)
            }
        }
        return toAdd
    }

    /// Called to close inventory overlay
    public func closeInventory() {
        isInventoryVisible = false
        pendingInventoryItemId = nil
    }

    /// Called when an equipment slot is tapped
    public func onEquipmentSlotTapped(_ slotType: HeroItemType) {
        let itemId = equipmentQueryService.equippedItemId(for: slotType, in: gameService.player.equipped)
        pendingInventoryItemId = itemId
        isInventoryVisible = true
    }

    /// Saves game and prepares for exit
    public func exitGame() async {
        try? await gameService.saveGame()
    }

    /// Called when a pocket slot is tapped
    public func onPocketTapped(_ index: Int) {
        print("Pocket tapped: \(index)")
    }
}

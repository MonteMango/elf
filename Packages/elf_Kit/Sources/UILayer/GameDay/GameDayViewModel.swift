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

    // MARK: - Local UI State

    public var activeBuffs: [String] = []
    public var isInventoryVisible: Bool = false

    /// Item ID to pre-select when inventory opens
    public var pendingInventoryItemId: UUID?

    // MARK: - Derived state (computed reactively)

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
        equipmentQueryService: any EquipmentQueryService
    ) {
        self.gameService = gameService
        self.progressionService = progressionService
        self.equipmentQueryService = equipmentQueryService
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
        default:
            print("Side menu tapped: \(menu.rawValue)")
        }
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

    /// Called when confirm action points button is tapped
    public func onConfirmActionPoints() async {
        gameService.advanceToNextDay()
        try? await gameService.saveGame()
    }
}

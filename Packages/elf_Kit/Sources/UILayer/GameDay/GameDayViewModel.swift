//
//  GameDayViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import Foundation

@Observable
@MainActor
public final class GameDayViewModel {

    // MARK: - Dependencies

    private let gameService: GameService

    // MARK: - UI State

    public var activeBuffs: [String]
    public var isInventoryVisible: Bool = false

    /// Item ID to pre-select when inventory opens
    public var pendingInventoryItemId: UUID?

    // MARK: - Game Access

    public var game: Game {
        gameService.game
    }

    // MARK: - Computed Properties (Player)

    public var characterName: String {
        game.player.name
    }

    public var characterLevel: Int16 {
        game.player.level
    }

    public var characterImageName: String {
        game.player.imageName
    }

    public var totalAttributes: HeroAttributes {
        game.player.totalAttributes
    }

    public var currentHP: Int {
        Int(game.player.currentHP)
    }

    public var maxHP: Int {
        Int(game.player.maxHP)
    }

    public var currentMP: Int {
        Int(game.player.currentMP)
    }

    public var maxMP: Int {
        Int(game.player.maxMP)
    }

    public var reputation: Int {
        game.player.reputation
    }

    public var equippedItems: [HeroItemType: UUID] {
        game.player.equippedItemIds
    }

    public var currentExp: Int {
        game.player.currentExp
    }

    public var expToNextLevel: Int {
        game.player.expToNextLevel
    }

    public var xpProgress: Double {
        game.player.expProgress
    }

    // MARK: - Computed Properties (Game State)

    public var gameState: GameState {
        game.gameState
    }

    // MARK: - Initialization

    public init(gameService: GameService) {
        self.gameService = gameService
        self.activeBuffs = []
    }

    // MARK: - Actions (UI only, no logic yet)

    /// Called when an action button is tapped (non-navigation actions only)
    public func onActionTapped(_ action: ActionType) {
        // Navigation is handled in View, this is for business logic only
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
        // Get the equipped item's instance ID for this slot
        let itemId = game.player.equipped.equippedItemId(for: slotType)
        pendingInventoryItemId = itemId
        isInventoryVisible = true
    }

    /// Called when a pocket slot is tapped
    public func onPocketTapped(_ index: Int) {
        // UI only - logic will be implemented later
        print("Pocket tapped: \(index)")
    }

    /// Called when confirm action points button is tapped
    public func onConfirmActionPoints() {
        // Spend all remaining action points and advance to next day
        gameService.advanceToNextDay()

        // Auto-save after day change
        Task {
            try? await gameService.saveGame()
        }
    }

    /// Save game (called when app goes to background)
    public func saveGame() async {
        try? await gameService.saveGame()
    }
}

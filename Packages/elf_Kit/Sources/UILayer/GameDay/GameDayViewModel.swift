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

    private let character: PlayerCharacter

    // MARK: - Game State

    public var gameState: GameState

    // MARK: - Character Stats

    public var currentHP: Int
    public var maxHP: Int
    public var currentMP: Int
    public var maxMP: Int
    public var reputation: Int

    // MARK: - Equipment & Buffs

    public var equippedItems: [HeroItemType: UUID]
    public var activeBuffs: [String]

    // MARK: - Experience

    public var currentExp: Int
    public var expToNextLevel: Int

    // MARK: - Computed Properties

    public var characterName: String {
        character.name
    }

    public var characterLevel: Int16 {
        character.level
    }

    public var characterImageName: String {
        character.appearance.imageName
    }

    public var totalAttributes: HeroAttributes {
        character.totalAttributes
    }

    public var xpProgress: Double {
        guard expToNextLevel > 0 else { return 0 }
        return Double(currentExp) / Double(expToNextLevel)
    }

    // MARK: - Initialization

    public init(character: PlayerCharacter) {
        self.character = character

        // Initialize game state with starting values
        let currentDay = GameDay(dayNumber: 1, dayType: .normal)
        let upcomingDays = [
            GameDay(dayNumber: 2, dayType: .dungeon),
            GameDay(dayNumber: 3, dayType: .normal),
            GameDay(dayNumber: 4, dayType: .houseWar)
        ]

        self.gameState = GameState(
            currentDay: currentDay,
            currentActionPoints: 100,
            maxActionPoints: 100,
            upcomingDays: upcomingDays
        )

        // Initialize character stats from attributes
        self.currentHP = Int(character.totalAttributes.hitPoints)
        self.maxHP = Int(character.totalAttributes.hitPoints)
        self.currentMP = Int(character.totalAttributes.manaPoints)
        self.maxMP = Int(character.totalAttributes.manaPoints)
        self.reputation = 148

        // Initialize empty equipment and buffs
        self.equippedItems = [:]
        self.activeBuffs = []

        // Initialize experience
        self.currentExp = 20
        self.expToNextLevel = 100
    }

    // MARK: - Actions (UI only, no logic yet)

    /// Called when an action button is tapped
    public func onActionTapped(_ action: ActionType) {
        // UI only - logic will be implemented later
        print("Action tapped: \(action.rawValue)")
    }

    /// Called when a side menu button is tapped
    public func onSideMenuTapped(_ menu: SideMenuType) {
        // UI only - logic will be implemented later
        print("Side menu tapped: \(menu.rawValue)")
    }

    /// Called when an equipment slot is tapped
    public func onEquipmentSlotTapped(_ slotType: HeroItemType) {
        // UI only - no navigation for now
        print("Equipment slot tapped: \(slotType)")
    }

    /// Called when a pocket slot is tapped
    public func onPocketTapped(_ index: Int) {
        // UI only - logic will be implemented later
        print("Pocket tapped: \(index)")
    }

    /// Called when confirm action points button is tapped
    public func onConfirmActionPoints() {
        // UI only - logic will be implemented later
        print("Confirm action points")
    }
}

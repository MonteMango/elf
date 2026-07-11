//
//  GameDayViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import Dependencies
import Foundation

@MainActor
@Observable
public final class GameDayViewModel {

    // MARK: - Dependencies (snapshotted at init)

    private let session: GameSession
    private let progressionService: any ProgressionService
    private let equipmentQueryService: any EquipmentQueryService
    private let equippedSlotResolver: any HeroEquippedSlotResolver
    private let itemsRepository: any ItemsRepository
    private let dungeonRepository: any DungeonRepository
    private let debugGameLogger: any DebugGameLogger

    // MARK: - Constants

    public let dungeonCost: Int = 100

    // MARK: - Local UI State

    public var activeBuffs: [String] = []
    public var isInventoryVisible: Bool = false

    /// Item ID to pre-select when inventory opens
    public var pendingInventoryItemId: UUID?

    // MARK: - Derived state (computed reactively)

    public var player: ElfInfo { session.state.player }

    public var characterLevel: Int {
        progressionService.calculateLevel(currentExp: session.state.player.currentExp)
    }
    public var expToNextLevel: Int {
        progressionService.expToNextLevel(currentExp: session.state.player.currentExp)
    }
    public var xpProgress: Double {
        progressionService.expProgress(currentExp: session.state.player.currentExp)
    }
    public var equippedItems: [HeroItemType: HeroEquippedSlot] {
        equippedSlotResolver.resolve(equipped: session.state.player.equipped)
    }

    // MARK: - Initialization

    public init(session: GameSession) {
        @Dependency(\.progressionService) var progressionService
        @Dependency(\.equipmentQueryService) var equipmentQueryService
        @Dependency(\.equippedSlotResolver) var equippedSlotResolver
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.dungeonRepository) var dungeonRepository
        @Dependency(\.debugGameLogger) var debugGameLogger
        self.progressionService = progressionService
        self.equipmentQueryService = equipmentQueryService
        self.equippedSlotResolver = equippedSlotResolver
        self.itemsRepository = itemsRepository
        self.dungeonRepository = dungeonRepository
        self.debugGameLogger = debugGameLogger

        self.session = session
    }

    /// Picks a random dungeon and freezes the squad of allies the hero will run with.
    /// Returns the chosen `dungeonId` plus the four ally member ids — both are passed
    /// through the route so reopening `DungeonOverviewScreen` with the same parameters
    /// shows the same squad. Returns `nil` if AP is insufficient or the dungeon pool is empty.
    /// Note: AP is **not** spent here — that happens when the run actually starts (follow-up PR).
    public func prepareDungeonRun() -> (dungeonId: DungeonID, allyIds: [ElfID])? {
        guard session.state.actionPoints.current >= dungeonCost else { return nil }
        guard let dungeon = dungeonRepository.randomDungeon() else { return nil }

        let house = session.state.houses[session.state.playerHouseIndex]
        let allyIds = house.members
            .enumerated()
            .filter { $0.offset != session.state.playerMemberIndex }
            .map(\.element.id)
            .shuffled()
            .prefix(4)
        return (dungeon.id, Array(allyIds))
    }

    // MARK: - Actions

    /// Called when an action button is tapped (non-navigation actions only)
    public func onActionTapped(_ action: ActionType) {
        debugGameLogger.logDebug("Action tapped: \(action.rawValue)")
    }

    /// Called when a side menu button is tapped
    public func onSideMenuTapped(_ menu: SideMenuType) {
        switch menu {
        case .items:
            isInventoryVisible.toggle()
        case .house:
            fillEquipmentInventory()
        default:
            debugGameLogger.logDebug("Side menu tapped: \(menu.rawValue)")
        }
    }

    /// Dev shortcut: ensure the player's inventory contains every weapon, shield and armor piece defined in the game.
    /// One-handed weapons (handUse `.oneHand`) top up to two copies; two-handed (`.both`),
    /// each shield and each armor slot top up to one. Copies already present (matched by base item id) are preserved.
    private func fillEquipmentInventory() {
        var toAdd: [Item] = []
        toAdd.append(contentsOf: missingWeapons())
        toAdd.append(contentsOf: missingShields())
        toAdd.append(contentsOf: missingArmor())
        session.addItemsToPlayerInventory(toAdd)
    }

    private func missingWeapons() -> [Item] {
        let allWeapons = itemsRepository.getItems(for: .weapons).compactMap { $0 as? WeaponItem }
        let existingCountByItemId = session.state.player.inventory.weapons
            .reduce(into: [ItemID: Int]()) { counts, weapon in counts[weapon.item.id, default: 0] += 1 }

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

    private func missingShields() -> [Item] {
        // `getItems(for: .shields)` also returns one-handed weapons (off-hand candidates),
        // so filter to actual shields to avoid duplicating weapon top-ups.
        let allShields = itemsRepository.getItems(for: .shields).compactMap { $0 as? ShieldItem }
        let existingItemIds = Set(session.state.player.inventory.shields.map { $0.item.id })
        return allShields.filter { !existingItemIds.contains($0.id) }
    }

    private func missingArmor() -> [Item] {
        let armorSlots: [HeroItemType] = [.helmet, .gloves, .shoes, .upperBody, .bottomBody]
        let existingItemIds = Set(session.state.player.inventory.armor.map { $0.item.id })

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
        let itemId = equipmentQueryService.equippedItemId(for: slotType, in: session.state.player.equipped)
        pendingInventoryItemId = itemId?.rawValue
        isInventoryVisible = true
    }

    /// Saves game and prepares for exit
    public func exitGame() async {
        try? await session.save()
    }

    /// Called when a pocket slot is tapped
    public func onPocketTapped(_ index: Int) {
        debugGameLogger.logDebug("Pocket tapped: \(index)")
    }
}

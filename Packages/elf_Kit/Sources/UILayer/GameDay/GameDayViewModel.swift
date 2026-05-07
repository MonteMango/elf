//
//  GameDayViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import Dependencies
import Foundation
import UIKit

@MainActor
@Observable
public final class GameDayViewModel {

    // MARK: - Dependencies (snapshotted at init)

    private let gameService: any GameService
    private let progressionService: any ProgressionService
    private let equipmentQueryService: any EquipmentQueryService
    private let itemsRepository: any ItemsRepository
    private let snapshotBuilder: any CombatantSnapshotBuilder
    private let monsterRepository: any MonsterRepository

    // MARK: - Constants

    public let dungeonCost: Int = 100

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
    public var equippedItems: [HeroItemType: HeroEquippedSlot] {
        let baseIds = equipmentQueryService.equippedBaseItemIds(from: gameService.player.equipped)
        var result: [HeroItemType: HeroEquippedSlot] = baseIds.mapValues { uuid in
            let candidateName = uuid.uuidString.lowercased()
            let resolvedName = UIImage(named: candidateName) != nil ? candidateName : nil
            return HeroEquippedSlot(id: uuid, imageName: resolvedName)
        }

        // Two-handed weapons occupy both hands but live in a single enum case,
        // so the off-hand slot is empty. Mirror the weapon icon there so the
        // user can see at a glance why the shield slot is unavailable.
        if case .twoHanded = gameService.player.equipped.weapons,
           let weaponSlot = result[.weapons] {
            result[.shields] = HeroEquippedSlot(
                id: weaponSlot.id,
                imageName: weaponSlot.imageName,
                mirroredFrom: .weapons
            )
        }
        return result
    }

    // MARK: - Initialization

    public init(gameService: any GameService) {
        @Dependency(\.progressionService) var progressionService
        @Dependency(\.equipmentQueryService) var equipmentQueryService
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.snapshotBuilder) var snapshotBuilder
        @Dependency(\.monsterRepository) var monsterRepository
        self.progressionService = progressionService
        self.equipmentQueryService = equipmentQueryService
        self.itemsRepository = itemsRepository
        self.snapshotBuilder = snapshotBuilder
        self.monsterRepository = monsterRepository

        self.gameService = gameService
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

    /// Dev shortcut: ensure the player's inventory contains every weapon, shield and armor piece defined in the game.
    /// One-handed weapons (handUse `.oneHand`) top up to two copies; two-handed (`.both`),
    /// each shield and each armor slot top up to one. Copies already present (matched by base item id) are preserved.
    private func fillEquipmentInventory() {
        var toAdd: [Item] = []
        toAdd.append(contentsOf: missingWeapons())
        toAdd.append(contentsOf: missingShields())
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

    private func missingShields() -> [Item] {
        // `getItems(for: .shields)` also returns one-handed weapons (off-hand candidates),
        // so filter to actual shields to avoid duplicating weapon top-ups.
        let allShields = itemsRepository.getItems(for: .shields).compactMap { $0 as? ShieldItem }
        let existingItemIds = Set(gameService.player.inventory.shields.map { $0.item.id })
        return allShields.filter { !existingItemIds.contains($0.id) }
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

    /// Assembles a 5v5 dungeon battle: hero + 4 random allies vs 5 wolves (level 1).
    /// Spends `dungeonCost` AP on success; returns nil if AP is insufficient or content is missing.
    public func startDungeonBattle() -> Battle? {
        guard gameService.actionPoints.current >= dungeonCost else { return nil }

        let wolves = monsterRepository.getMonsters(world: .upper, level: 1)
            .filter { $0.title == "Wolf" }
        guard let wolfTemplate = wolves.first else { return nil }
        let wolfSnapshots: [CombatantSnapshot] = (0..<5).map { _ in
            snapshotBuilder.buildSnapshot(from: wolfTemplate)
        }

        let player = gameService.player.snapshot()
        let heroSnapshot = snapshotBuilder.buildSnapshot(
            name: player.name,
            imageName: player.imageName,
            level: progressionService.calculateLevel(currentExp: player.currentExp),
            fightStyleAttributes: player.fightStyleAttributes,
            randomLevelAttributes: player.randomLevelAttributes,
            equipped: player.equipped
        )

        let house = gameService.houses[gameService.playerHouseIndex]
        let allies = house.members
            .enumerated()
            .filter { $0.offset != gameService.playerMemberIndex }
            .map(\.element)
            .shuffled()
            .prefix(4)
        let allySnapshots: [CombatantSnapshot] = allies.map { ally in
            snapshotBuilder.buildSnapshot(
                name: ally.name,
                imageName: ally.imageName,
                level: progressionService.calculateLevel(currentExp: ally.currentExp),
                fightStyleAttributes: ally.fightStyleAttributes,
                randomLevelAttributes: ally.randomLevelAttributes,
                equipped: ally.equipped
            )
        }

        gameService.spendActionPoints(dungeonCost)

        return Battle(
            leftTeam: [heroSnapshot] + allySnapshots,
            rightTeam: wolfSnapshots
        )
    }

    /// Called when a pocket slot is tapped
    public func onPocketTapped(_ index: Int) {
        print("Pocket tapped: \(index)")
    }
}

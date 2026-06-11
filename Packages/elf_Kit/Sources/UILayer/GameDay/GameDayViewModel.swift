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
    private let snapshotBuilder: any CombatantSnapshotBuilder
    private let monsterRepository: any MonsterRepository
    private let dungeonRepository: any DungeonRepository

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
        @Dependency(\.snapshotBuilder) var snapshotBuilder
        @Dependency(\.monsterRepository) var monsterRepository
        @Dependency(\.dungeonRepository) var dungeonRepository
        self.progressionService = progressionService
        self.equipmentQueryService = equipmentQueryService
        self.equippedSlotResolver = equippedSlotResolver
        self.itemsRepository = itemsRepository
        self.snapshotBuilder = snapshotBuilder
        self.monsterRepository = monsterRepository
        self.dungeonRepository = dungeonRepository

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

    /// Assembles a 5v5 dungeon battle: hero + 4 random allies vs 5 wolves (level 1).
    /// Spends `dungeonCost` AP on success; returns nil if AP is insufficient or content is missing.
    public func startDungeonBattle() -> Battle? {
        guard session.state.actionPoints.current >= dungeonCost else { return nil }

        let wolves = monsterRepository.getMonsters(world: .upper, level: 1)
            .filter { $0.title == "Wolf" }
        guard let wolfTemplate = wolves.first else { return nil }
        let wolfSnapshots: [CombatantSnapshot] = (0..<5).map { _ in
            snapshotBuilder.buildSnapshot(from: wolfTemplate, globalBuffs: [])
        }

        let player = session.state.player
        let heroSnapshot = snapshotBuilder.buildSnapshot(
            elf: player,
            level: progressionService.calculateLevel(currentExp: player.currentExp),
            globalBuffs: player.globalBuffs
        )

        let house = session.state.houses[session.state.playerHouseIndex]
        let allies = house.members
            .enumerated()
            .filter { $0.offset != session.state.playerMemberIndex }
            .map(\.element)
            .shuffled()
            .prefix(4)
        let allySnapshots: [CombatantSnapshot] = allies.map { ally in
            snapshotBuilder.buildSnapshot(
                elf: ally,
                level: progressionService.calculateLevel(currentExp: ally.currentExp),
                globalBuffs: ally.globalBuffs
            )
        }

        session.spendActionPoints(dungeonCost)

        // Pre-resolve UI equipment maps for every elf-side combatant. Keyed by
        // snapshot id; monsters carry no entry (consumer falls back to [:]).
        var equipmentMap: [CombatantID: [HeroItemType: HeroEquippedSlot]] = [
            heroSnapshot.id: equippedSlotResolver.resolve(equipped: player.equipped)
        ]
        for (snapshot, ally) in zip(allySnapshots, allies) {
            equipmentMap[snapshot.id] = equippedSlotResolver.resolve(equipped: ally.equipped)
        }

        return Battle(
            leftTeam: [heroSnapshot] + allySnapshots,
            rightTeam: wolfSnapshots,
            equippedItemsByCombatantId: equipmentMap
        )
    }

    /// Called when a pocket slot is tapped
    public func onPocketTapped(_ index: Int) {
        print("Pocket tapped: \(index)")
    }
}

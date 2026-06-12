//
//  GameSession.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Public facade for an active game session. Owns the observable `state`
/// (`GameStore`), the dungeon child session, the day-state shortcut, and
/// every game-level mutation + persistence operation.
///
/// Views and ViewModels go through `GameSession` exclusively. State reads via
/// `session.state.X`; mutations via `session.X(...)`; persistence via
/// `session.save()`. There is no separate "service" layer underneath — the
/// mutation logic lives directly in this type.
///
/// Lifecycle: created when a game starts, released when it ends (see
/// `AppCoordinator.startGame` / `endGame`).
@MainActor
@Observable
public final class GameSession {

    // MARK: - State

    public let state: GameStore

    // MARK: - Child sessions

    public var dungeonSession: DungeonSession?

    // MARK: - Private dependencies

    private let gameRepository: any GameSaveStorage
    private let debugGameLogger: any DebugGameLogger
    private let inventoryService: any InventoryService
    private let craftService: any CraftService
    private let buffsRepository: any BuffsRepository
    private let buffApplicationService: any BuffApplicationService

    private let slotId: String

    // MARK: - Initialization

    public init(
        game: Game,
        playTime: TimeInterval = 0,
        slotId: String = SaveSlotInfo.defaultSlotId
    ) {
        @Dependency(\.gameRepository) var gameRepository
        @Dependency(\.debugGameLogger) var debugGameLogger
        @Dependency(\.inventoryService) var inventoryService
        @Dependency(\.craftService) var craftService
        @Dependency(\.buffsRepository) var buffsRepository
        @Dependency(\.buffApplicationService) var buffApplicationService
        self.gameRepository = gameRepository
        self.debugGameLogger = debugGameLogger
        self.inventoryService = inventoryService
        self.craftService = craftService
        self.buffsRepository = buffsRepository
        self.buffApplicationService = buffApplicationService
        self.state = GameStore(from: game, playTime: playTime)
        self.slotId = slotId
    }

    // MARK: - Day Management

    /// Advances to the next day in the calendar. Resets action points for every
    /// elf (player and AI) and expires global buffs whose `durationDays` has
    /// elapsed.
    public func advanceToNextDay() {
        let nextDayNumber = state.currentDay.dayNumber + 1
        guard let nextDayIndex = state.calendar.firstIndex(where: { $0.dayNumber == nextDayNumber }) else {
            return
        }
        state.currentDay = state.calendar[nextDayIndex]
        resetActionPointsForAllElves()
        expireGlobalBuffs(currentDayNumber: nextDayNumber)
    }

    /// Refills every elf's per-day action points to maximum. Player AP is
    /// included (the player is one of the roster members).
    private func resetActionPointsForAllElves() {
        for houseIndex in state.houses.indices {
            for memberIndex in state.houses[houseIndex].members.indices {
                let current = state.houses[houseIndex].members[memberIndex].actionPoints
                state.houses[houseIndex].members[memberIndex].actionPoints = current.reset()
            }
        }
    }

    private func expireGlobalBuffs(currentDayNumber: Int) {
        for houseIndex in state.houses.indices {
            for memberIndex in state.houses[houseIndex].members.indices {
                let current = state.houses[houseIndex].members[memberIndex].globalBuffs
                let kept = current.filter { applied in
                    guard let buff = buffsRepository.getById(id: applied.buffId),
                          let duration = buff.durationDays,
                          let appliedOnDay = applied.appliedOnDay else {
                        return true  // unknown buff, no expiry, or missing day → keep
                    }
                    return currentDayNumber - appliedOnDay < duration
                }
                if kept.count != current.count {
                    state.houses[houseIndex].members[memberIndex].globalBuffs = kept
                }
            }
        }
    }

    /// Spends action points for an activity. No-op if insufficient.
    public func spendActionPoints(_ amount: Int) {
        if case .success(let newPoints) = state.actionPoints.spend(amount) {
            state.actionPoints = newPoints
        }
    }

    // MARK: - Player Progression

    public func addPlayerExperience(_ amount: Int) {
        state.player.currentExp += amount
    }

    public func addFishingExperience(_ amount: Int) {
        state.player.fishingExp += amount
    }

    public func addForagingExperience(_ amount: Int) {
        state.player.foragingExp += amount
    }

    public func addMiningExperience(_ amount: Int) {
        state.player.miningExp += amount
    }

    /// Adds hunt rewards (drops) to the player's inventory.
    public func addDropsToPlayerInventory(rewards: HuntRewards) {
        let additions = rewards.materials.map {
            MaterialAddition(ref: .monster($0.id), quantity: $0.amount)
        }
        var inventory = inventoryService.addMaterials(additions, to: state.player.inventory)
        if let weapon = rewards.weapon {
            inventory = inventoryService.addWeapon(weapon, to: inventory)
        }
        if let armor = rewards.armor {
            inventory = inventoryService.addArmor(armor, to: inventory)
        }
        state.player.inventory = inventory
    }

    /// Adds caught fish to the player's inventory as materials.
    public func addFishToInventory(_ fish: [Fish]) {
        let additions = fish.map {
            MaterialAddition(ref: .fish($0.id), quantity: 1)
        }
        state.player.inventory = inventoryService.addMaterials(additions, to: state.player.inventory)
    }

    /// Adds gathered herbs to the player's inventory as materials.
    public func addHerbsToInventory(_ herbs: [Herb]) {
        let additions = herbs.map {
            MaterialAddition(ref: .herb($0.id), quantity: 1)
        }
        state.player.inventory = inventoryService.addMaterials(additions, to: state.player.inventory)
    }

    /// Adds mined ores to the player's inventory as materials.
    public func addOresToInventory(_ ores: [Ore]) {
        let additions = ores.map {
            MaterialAddition(ref: .ore($0.id), quantity: 1)
        }
        state.player.inventory = inventoryService.addMaterials(additions, to: state.player.inventory)
    }

    /// Adds the given hero items to the player's inventory, routed by concrete
    /// type (weapon / armor / shield / robe). Used by dev shortcuts that seed
    /// equipment in bulk.
    public func addItemsToPlayerInventory(_ items: [Item]) {
        var inventory = state.player.inventory
        for item in items {
            inventory = inventoryService.addCraftedItem(item, to: inventory)
        }
        state.player.inventory = inventory
    }

    // MARK: - Buffs

    // NOTE: The buff catalog currently ships no global-scope buffs (the
    // global `Exhausted` variant was retired 2026-06; only the battle-scoped
    // one remains), so these two entry points have no valid `buffId` to
    // receive yet. Kept deliberately: global buffs (activities, potions,
    // day-scoped effects) are planned — this is the chokepoint they'll
    // arrive through. Do not remove as "dead code".

    /// Applies a global-scope buff to the player respecting the buff's
    /// `stackingRule`. Scope is enforced by `BuffApplicationService.applyAsGlobal`.
    public func applyGlobalBuffToPlayer(buffId: BuffID) {
        state.player.globalBuffs = buffApplicationService.applyAsGlobal(
            buffId: buffId,
            to: state.player.globalBuffs,
            currentDay: state.currentDay.dayNumber
        )
    }

    /// Applies a global-scope buff to a specific elf in the roster.
    public func applyGlobalBuff(buffId: BuffID, toElfAt houseIndex: Int, memberIndex: Int) {
        guard houseIndex >= 0, houseIndex < state.houses.count,
              memberIndex >= 0, memberIndex < state.houses[houseIndex].members.count else {
            return
        }
        state.houses[houseIndex].members[memberIndex].globalBuffs = buffApplicationService.applyAsGlobal(
            buffId: buffId,
            to: state.houses[houseIndex].members[memberIndex].globalBuffs,
            currentDay: state.currentDay.dayNumber
        )
    }

    // MARK: - Crafting

    /// Atomically crafts `item` from `recipe`: validates materials, deducts
    /// ingredients, and adds the crafted item to inventory. Returns `true` on
    /// success, `false` if materials are insufficient.
    @discardableResult
    public func craftItem(recipe: Recipe, item: Item) -> Bool {
        var inventory = state.player.inventory
        guard craftService.canCraft(recipe: recipe, inventory: inventory) else { return false }
        inventory = craftService.deductMaterials(recipe: recipe, from: inventory)
        inventory = inventoryService.addCraftedItem(item, to: inventory)
        state.player.inventory = inventory
        return true
    }

    // MARK: - Equipment

    // Resolved lazily at point of use (not snapshotted in `init`): the equip
    // methods are the only place it is needed, so most `GameSession` tests never
    // touch it. That lets the dependency stay without a `testValue` — a test that
    // exercises an equip path without wiring it fails loudly ("no test
    // implementation") instead of silently using a stub.
    private var equipmentService: any EquipmentService {
        @Dependency(\.equipmentService) var equipmentService
        return equipmentService
    }

    // Each method reads the player's current `equipped` (+ `inventory` where a
    // lookup is needed), delegates the pure transform to `equipmentService`, and
    // writes the result back — `@Observable` on `houses` then invalidates any
    // SwiftUI view reading the equipped chain. No-op transforms write back an
    // unchanged value (harmless).

    public func equipWeapon(id: OwnedItemID) {
        let player = state.player
        state.player.equipped = equipmentService.equipWeapon(
            id: id, in: player.equipped, inventory: player.inventory
        )
    }

    public func equipOffhandWeapon(id: OwnedItemID) {
        let player = state.player
        state.player.equipped = equipmentService.equipOffhandWeapon(
            id: id, in: player.equipped, inventory: player.inventory
        )
    }

    public func unequipWeapon(id: OwnedItemID) {
        state.player.equipped = equipmentService.unequipWeapon(id: id, in: state.player.equipped)
    }

    public func equipShield(id: OwnedItemID) {
        let player = state.player
        state.player.equipped = equipmentService.equipShield(
            id: id, in: player.equipped, inventory: player.inventory
        )
    }

    public func unequipShield() {
        state.player.equipped = equipmentService.unequipShield(in: state.player.equipped)
    }

    public func equipArmor(id: OwnedItemID) {
        let player = state.player
        state.player.equipped = equipmentService.equipArmor(
            id: id, in: player.equipped, inventory: player.inventory
        )
    }

    public func unequipArmor(id: OwnedItemID) {
        state.player.equipped = equipmentService.unequipArmor(id: id, in: state.player.equipped)
    }

    public func equipJewelry(id: OwnedItemID) {
        let player = state.player
        state.player.equipped = equipmentService.equipJewelry(
            id: id, in: player.equipped, inventory: player.inventory
        )
    }

    public func unequipJewelry(id: OwnedItemID) {
        state.player.equipped = equipmentService.unequipJewelry(id: id, in: state.player.equipped)
    }

    // MARK: - Persistence

    // TODO: [persistence/P0] Coalesce/debounce rapid save() calls.
    /// Saves the active game state. Snapshots the store on the main thread,
    /// then offloads disk I/O to the repository (background actor).
    public func save() async throws {
        let snap = state.snapshot()
        let time = state.playTime
        debugGameLogger.logGameSave(game: snap, playTime: time)
        try await gameRepository.save(snap, slotId: slotId, playTime: time)
    }

    // MARK: - Dungeon Session Lifecycle

    @discardableResult
    public func startDungeonSession(dungeonId: DungeonID, allyIds: [ElfID]) -> DungeonSession {
        let session = DungeonSession(
            gameStore: state,
            dungeonId: dungeonId,
            allyIds: allyIds
        )
        dungeonSession = session
        return session
    }

    public func endDungeonSession() {
        dungeonSession = nil
    }
}

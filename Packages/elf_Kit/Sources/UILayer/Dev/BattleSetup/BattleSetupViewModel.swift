//
//  BattleSetupViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import Foundation

@MainActor
@Observable
public final class BattleSetupViewModel {

    // MARK: - Dependencies

    private let itemsRepository: any ItemsRepository
    private let attributeService: any AttributeService
    private let armorService: any ArmorService
    private let damageService: any DamageService
    private let weaponValidator: any WeaponValidator
    private let snapshotBuilder: any CombatantSnapshotBuilder
    private let monsterRepository: any MonsterRepository

    // MARK: - State

    public var presentedItemSelector: ItemSelectorState?

    /// Selected opponent type (elf or monster)
    public var selectedOpponent: OpponentSelection = .elf

    /// All available monsters for the picker
    public private(set) var allMonsters: [Monster] = []

    // Hero configurations
    public var playerState = HeroConfigurationState()
    public var botState = HeroConfigurationState()

    // MARK: - Private State

    // Task properties for background work cancellation
    //
    // Using nonisolated(unsafe) because:
    // 1. @Observable macro makes these mutable stored properties
    // 2. nonisolated cannot be applied to mutable stored properties
    //
    // Thread safety justification:
    // - Task.cancel() is thread-safe by design
    // - deinit only calls cancel(), which is safe even if racing with setters
    // - Setters (setAttributesTask, setEquipmentTask) are @MainActor isolated
    // - Potential race: deinit vs setter - acceptable because cancel() is idempotent
    private nonisolated(unsafe) var playerAttributesTask: Task<Void, Never>?
    private nonisolated(unsafe) var botAttributesTask: Task<Void, Never>?
    private nonisolated(unsafe) var playerEquipmentTask: Task<Void, Never>?
    private nonisolated(unsafe) var botEquipmentTask: Task<Void, Never>?

    // MARK: - Hero Type Accessors

    private func state(for heroType: HeroType) -> HeroConfigurationState {
        heroType == .player ? playerState : botState
    }

    private func level(for heroType: HeroType) -> Int {
        state(for: heroType).level
    }

    private func fightStyle(for heroType: HeroType) -> FightStyle? {
        state(for: heroType).fightStyle
    }

    private func selectedItems(for heroType: HeroType) -> [HeroItemType: UUID?] {
        state(for: heroType).selectedItems
    }

    private func setFightStyleAttributes(_ attrs: HeroAttributes?, for heroType: HeroType) {
        state(for: heroType).fightStyleAttributes = attrs
    }

    private func setLevelRandomAttributes(_ attrs: HeroAttributes?, for heroType: HeroType) {
        state(for: heroType).levelRandomAttributes = attrs
    }

    private func setTwoHandedWeaponId(_ id: UUID?, for heroType: HeroType) {
        state(for: heroType).twoHandedWeaponId = id
    }

    private func setItemsAttributes(_ attrs: HeroAttributes?, for heroType: HeroType) {
        state(for: heroType).itemsAttributes = attrs
    }

    private func setArmorValues(_ values: [BodyPart: Int16], for heroType: HeroType) {
        state(for: heroType).armorValues = values
    }

    private func setLeftHandDamage(_ damage: (minDmg: Int16, maxDmg: Int16)?, for heroType: HeroType) {
        state(for: heroType).leftHandDamage = damage
    }

    private func setRightHandDamage(_ damage: (minDmg: Int16, maxDmg: Int16)?, for heroType: HeroType) {
        state(for: heroType).rightHandDamage = damage
    }

    // Task accessors
    private func attributesTask(for heroType: HeroType) -> Task<Void, Never>? {
        heroType == .player ? playerAttributesTask : botAttributesTask
    }

    private func setAttributesTask(_ task: Task<Void, Never>?, for heroType: HeroType) {
        if heroType == .player {
            playerAttributesTask = task
        } else {
            botAttributesTask = task
        }
    }

    private func equipmentTask(for heroType: HeroType) -> Task<Void, Never>? {
        heroType == .player ? playerEquipmentTask : botEquipmentTask
    }

    private func setEquipmentTask(_ task: Task<Void, Never>?, for heroType: HeroType) {
        if heroType == .player {
            playerEquipmentTask = task
        } else {
            botEquipmentTask = task
        }
    }

    // MARK: - Initialization

    public init(
        itemsRepository: any ItemsRepository,
        attributeService: any AttributeService,
        armorService: any ArmorService,
        damageService: any DamageService,
        weaponValidator: any WeaponValidator,
        snapshotBuilder: any CombatantSnapshotBuilder,
        monsterRepository: any MonsterRepository
    ) {
        self.itemsRepository = itemsRepository
        self.attributeService = attributeService
        self.armorService = armorService
        self.damageService = damageService
        self.weaponValidator = weaponValidator
        self.snapshotBuilder = snapshotBuilder
        self.monsterRepository = monsterRepository

        Task { await loadAllMonsters() }
    }

    // MARK: - Monster Loading

    private func loadAllMonsters() async {
        var monsters: [Monster] = []
        for world in [WorldType.upper, WorldType.middle, WorldType.lower] {
            for level in 1...3 {
                let worldMonsters = monsterRepository.getMonsters(world: world, level: level)
                monsters.append(contentsOf: worldMonsters)
            }
        }
        allMonsters = monsters
    }

    deinit {
        // Cancel all active tasks to prevent memory leaks and ensure proper cleanup
        playerAttributesTask?.cancel()
        botAttributesTask?.cancel()
        playerEquipmentTask?.cancel()
        botEquipmentTask?.cancel()
    }

    // MARK: - Public API for State Updates

    public func updatePlayerLevel(_ newLevel: Int) {
        playerState.level = newLevel
        schedulePlayerUpdate()
    }

    public func updatePlayerFightStyle(_ newStyle: FightStyle?) {
        playerState.fightStyle = newStyle
        schedulePlayerUpdate()
    }

    public func updateBotLevel(_ newLevel: Int) {
        botState.level = newLevel
        scheduleBotUpdate()
    }

    public func updateBotFightStyle(_ newStyle: FightStyle?) {
        botState.fightStyle = newStyle
        scheduleBotUpdate()
    }

    // MARK: - Actions

    public func handlePlayerItemSelection(itemType: HeroItemType) {
        handleItemSelection(for: .player, itemType: itemType)
    }

    public func handleBotItemSelection(itemType: HeroItemType) {
        handleItemSelection(for: .bot, itemType: itemType)
    }

    private func handleItemSelection(for heroType: HeroType, itemType: HeroItemType) {
        let currentItemId = getCurrentItemId(for: heroType, itemType: itemType)

        presentedItemSelector = ItemSelectorState(
            heroType: heroType,
            itemType: itemType,
            currentItemId: currentItemId
        )
    }

    // MARK: - Public API

    public func equipItem(for heroType: HeroType, itemType: HeroItemType, selectedItemId: UUID?) {
        updateSelectedItems(for: heroType, itemType: itemType, selectedItemId: selectedItemId)
    }

    // MARK: - Private Methods

    private func updateSelectedItems(for heroType: HeroType, itemType: HeroItemType, selectedItemId: UUID?) {
        if requiresValidation(itemType) {
            Task {
                let currentState = state(for: heroType)
                let currentItems = currentState.selectedItems
                let validatedItems = await self.weaponValidator.validateAndResolve(
                    selecting: selectedItemId,
                    for: itemType,
                    currentItems: currentItems
                )

                currentState.selectedItems = validatedItems
                scheduleEquipmentUpdate(for: heroType)
            }
        } else {
            // Other items don't need validation
            let currentState = state(for: heroType)
            currentState.selectedItems[itemType] = selectedItemId
            scheduleEquipmentUpdate(for: heroType)
        }
    }

    private func requiresValidation(_ itemType: HeroItemType) -> Bool {
        return itemType == .weapons || itemType == .shields
    }

    private func getCurrentItemId(for heroType: HeroType, itemType: HeroItemType) -> UUID? {
        return state(for: heroType).selectedItems[itemType] ?? nil
    }

    // MARK: - Generic Attribute Updates

    private func scheduleAttributesUpdate(for heroType: HeroType) {
        // Cancel previous task
        attributesTask(for: heroType)?.cancel()

        // Capture current values for validation
        let currentLevel = level(for: heroType)
        let currentStyle = fightStyle(for: heroType)

        guard let fightStyle = currentStyle else {
            // Clear attributes if no fight style selected
            setFightStyleAttributes(nil, for: heroType)
            setLevelRandomAttributes(nil, for: heroType)
            return
        }

        let task = Task {
            do {
                // Debounce: Wait 250ms
                try await Task.sleep(for: .milliseconds(250))

                // Check if cancelled during sleep
                guard !Task.isCancelled else { return }

                // Validate values haven't changed during debounce
                guard level(for: heroType) == currentLevel,
                      self.fightStyle(for: heroType) == currentStyle else {
                    return  // Values changed - this task is outdated
                }

                let fsAttrs = attributeService.getAllFightStyleAttributes(
                    for: fightStyle,
                    at: Int16(currentLevel)
                )
                let lrAttrs = attributeService.getAllRandomLevelAttributes(
                    for: Int16(currentLevel)
                )

                // Final validation before updating UI
                guard !Task.isCancelled,
                      level(for: heroType) == currentLevel,
                      self.fightStyle(for: heroType) == currentStyle else {
                    return  // Values changed during fetch
                }

                // Safe to update
                setFightStyleAttributes(fsAttrs, for: heroType)
                setLevelRandomAttributes(lrAttrs, for: heroType)

            } catch is CancellationError {
                // Task was cancelled - this is expected
                return
            } catch {
                // Handle other errors
                print("Error updating \(heroType) attributes: \(error)")
            }
        }

        setAttributesTask(task, for: heroType)
    }

    // MARK: - Player/Bot Wrapper Methods

    private func schedulePlayerUpdate() {
        scheduleAttributesUpdate(for: .player)
    }

    private func scheduleBotUpdate() {
        scheduleAttributesUpdate(for: .bot)
    }

    // MARK: - Consolidated Equipment Updates

    /// Consolidates all equipment-related updates into a single async task
    /// This includes: two-handed weapon check, items attributes, armor values, and damage calculation
    private func scheduleEquipmentUpdate(for heroType: HeroType) {
        // Cancel previous task
        equipmentTask(for: heroType)?.cancel()

        // Capture current items for validation
        let currentItems = selectedItems(for: heroType)

        let task = Task {
            do {
                // Debounce: Wait 250ms to avoid excessive updates during rapid equipment changes
                try await Task.sleep(for: .milliseconds(250))

                // Check if cancelled during sleep
                guard !Task.isCancelled else { return }

                // Validate items haven't changed during debounce
                guard selectedItems(for: heroType) == currentItems else {
                    return  // Items changed - this task is outdated
                }

                // Extract item IDs
                let itemIds = currentItems.values.compactMap { $0 }
                let primaryWeaponId = currentItems[.weapons] ?? nil
                let secondaryWeaponId = currentItems[.shields] ?? nil

                let attrs = attributeService.getAllItemsAttributes(for: itemIds)
                let armor = armorService.getAllItemsArmor(for: itemIds)

                var twoHandedWeaponId: UUID?
                let isTwoHanded: Bool
                if let weaponId = primaryWeaponId,
                   let item = itemsRepository.getHeroItem(weaponId),
                   let weapon = item as? WeaponItem,
                   weapon.handUse == .both {
                    isTwoHanded = true
                    twoHandedWeaponId = weapon.id
                } else {
                    isTwoHanded = false
                }

                let rightHandDamage: (minDmg: Int16, maxDmg: Int16)?
                let leftHandDamage: (minDmg: Int16, maxDmg: Int16)?
                if isTwoHanded {
                    rightHandDamage = damageService.getWeaponDamage(weaponId: primaryWeaponId)
                    leftHandDamage = (minDmg: 0, maxDmg: 0)
                } else {
                    rightHandDamage = damageService.getWeaponDamage(weaponId: primaryWeaponId)
                    leftHandDamage = damageService.getWeaponDamage(weaponId: secondaryWeaponId)
                }

                // Final validation before updating UI
                guard !Task.isCancelled,
                      selectedItems(for: heroType) == currentItems else {
                    return  // Items changed during fetch
                }

                // Update all properties in one batch
                setItemsAttributes(attrs, for: heroType)
                setArmorValues(armor, for: heroType)
                setTwoHandedWeaponId(twoHandedWeaponId, for: heroType)
                setRightHandDamage(rightHandDamage, for: heroType)
                setLeftHandDamage(leftHandDamage, for: heroType)

            } catch is CancellationError {
                // Task was cancelled - this is expected
                return
            } catch {
                // Handle other errors
                print("Error updating \(heroType) equipment: \(error)")
            }
        }

        setEquipmentTask(task, for: heroType)
    }

    // MARK: - Battle Creation

    /// Create a Battle instance from current player and bot configurations
    /// - Returns: Battle instance or nil if validation fails
    public func startBattle() async -> Battle? {
        // Validate player configuration
        guard let playerFightStyleAttrs = playerState.fightStyleAttributes,
              let playerLevelAttrs = playerState.levelRandomAttributes else {
            return nil
        }

        // Build CombatantSnapshot for player
        guard let playerSnapshot = snapshotBuilder.buildSnapshot(
            name: "Player",
            imageName: "Yuuki Asuna",
            level: playerState.level,
            fightStyleAttributes: playerFightStyleAttrs,
            randomLevelAttributes: playerLevelAttrs,
            selectedItems: playerState.selectedItems
        ) else {
            return nil
        }

        // Handle opponent based on selection
        switch selectedOpponent {
        case .elf:
            // Validate bot configuration for elf opponent
            guard let botFightStyleAttrs = botState.fightStyleAttributes,
                  let botLevelAttrs = botState.levelRandomAttributes else {
                return nil
            }

            // Build CombatantSnapshot for bot
            guard let botSnapshot = snapshotBuilder.buildSnapshot(
                name: "Bot",
                imageName: "",
                level: botState.level,
                fightStyleAttributes: botFightStyleAttrs,
                randomLevelAttributes: botLevelAttrs,
                selectedItems: botState.selectedItems
            ) else {
                return nil
            }

            // Create Battle with elf opponent
            return Battle(
                leftTeam: [playerSnapshot],
                rightTeam: [botSnapshot]
            )

        case .monster(let monster):
            // Build CombatantSnapshot from monster
            let monsterSnapshot = snapshotBuilder.buildSnapshot(from: monster)

            // Create Battle with monster opponent
            return Battle(
                leftTeam: [playerSnapshot],
                rightTeam: [monsterSnapshot]
            )
        }
    }
}

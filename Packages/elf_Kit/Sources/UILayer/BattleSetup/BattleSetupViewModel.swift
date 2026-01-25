//
//  BattleSetupViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import Foundation

@Observable
@MainActor
public final class BattleSetupViewModel {

    // MARK: - Hero Configuration State

    @Observable
    public final class HeroConfigurationState {
        public var level: Int
        public var fightStyle: FightStyle?
        public var fightStyleAttributes: HeroAttributes?
        public var levelRandomAttributes: HeroAttributes?
        public var itemsAttributes: HeroAttributes?
        public var armorValues: [BodyPart: Int16]
        public var leftHandDamage: (minDmg: Int16, maxDmg: Int16)?
        public var rightHandDamage: (minDmg: Int16, maxDmg: Int16)?
        public var selectedItems: [HeroItemType: UUID?]
        public var twoHandedWeaponId: UUID?

        public var totalAttributes: HeroAttributes? {
            guard let fightStyle = fightStyleAttributes,
                  let level = levelRandomAttributes else {
                return nil
            }

            let items = itemsAttributes ?? HeroAttributes()

            return HeroAttributes(
                hitPoints: fightStyle.hitPoints + level.hitPoints + items.hitPoints,
                manaPoints: fightStyle.manaPoints + level.manaPoints + items.manaPoints,
                agility: fightStyle.agility + level.agility + items.agility,
                strength: fightStyle.strength + level.strength + items.strength,
                power: fightStyle.power + level.power + items.power,
                instinct: fightStyle.instinct + level.instinct + items.instinct
            )
        }

        public init(level: Int = 1) {
            self.level = level
            self.fightStyle = nil
            self.fightStyleAttributes = nil
            self.levelRandomAttributes = nil
            self.itemsAttributes = nil
            self.armorValues = [:]
            self.leftHandDamage = nil
            self.rightHandDamage = nil
            self.selectedItems = [:]
            self.twoHandedWeaponId = nil
        }
    }

    // MARK: - Item Selector State

    public struct ItemSelectorState: Identifiable {
        public let id = UUID()
        public let heroType: HeroType
        public let itemType: HeroItemType
        public let currentItemId: UUID?

        public init(heroType: HeroType, itemType: HeroItemType, currentItemId: UUID?) {
            self.heroType = heroType
            self.itemType = itemType
            self.currentItemId = currentItemId
        }
    }

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

        loadAllMonsters()
    }

    // MARK: - Monster Loading

    private func loadAllMonsters() {
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

                // Fetch attributes in parallel on background thread
                let service = attributeService
                let levelInt16 = Int16(currentLevel)

                let (fsAttrs, lrAttrs) = await Task.detached(priority: .userInitiated) {
                    async let fightStyleAttrs = service.getAllFightStyleAttributes(
                        for: fightStyle,
                        at: levelInt16
                    )
                    async let levelRandomAttrs = service.getAllRandomLevelAttributes(
                        for: levelInt16
                    )
                    return await (fightStyleAttrs, levelRandomAttrs)
                }.value

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

                // Fetch all data in parallel on background thread
                let attrService = attributeService
                let armService = armorService
                let dmgService = damageService
                let itemsRepo = itemsRepository

                let (attrs, armor, twoHandedWeaponId, rightHandDamage, leftHandDamage) = await Task.detached(priority: .userInitiated) {
                    async let itemsAttrs = attrService.getAllItemsAttributes(for: itemIds)
                    async let armorVals = armService.getAllItemsArmor(for: itemIds)

                    // Check two-handed weapon and calculate damage
                    var isTwoHanded = false
                    var twoHandedId: UUID?

                    if let weaponId = primaryWeaponId,
                       let item = itemsRepo.getHeroItem(weaponId),
                       let weapon = item as? WeaponItem {
                        if weapon.handUse == .both {
                            isTwoHanded = true
                            twoHandedId = weapon.id
                        }
                    }

                    let rightDmg: (minDmg: Int16, maxDmg: Int16)?
                    let leftDmg: (minDmg: Int16, maxDmg: Int16)?

                    if isTwoHanded {
                        rightDmg = await dmgService.getWeaponDamage(weaponId: primaryWeaponId)
                        leftDmg = (minDmg: 0, maxDmg: 0)
                    } else {
                        rightDmg = await dmgService.getWeaponDamage(weaponId: primaryWeaponId)
                        leftDmg = await dmgService.getWeaponDamage(weaponId: secondaryWeaponId)
                    }

                    let (a, ar) = await (itemsAttrs, armorVals)
                    return (a, ar, twoHandedId, rightDmg, leftDmg)
                }.value

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

    private func schedulePlayerEquipmentUpdate() {
        scheduleEquipmentUpdate(for: .player)
    }

    private func scheduleBotEquipmentUpdate() {
        scheduleEquipmentUpdate(for: .bot)
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
        guard let playerSnapshot = await snapshotBuilder.buildSnapshot(
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
            guard let botSnapshot = await snapshotBuilder.buildSnapshot(
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

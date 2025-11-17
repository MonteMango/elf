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

    private let itemsRepository: ItemsRepository
    private let attributeService: AttributeService
    private let armorService: ArmorService
    private let damageService: DamageService
    private let weaponValidator: WeaponValidator
    private let elfHeroBuilder: ElfHeroBuilder

    // MARK: - State

    public var presentedItemSelector: ItemSelectorState?

    // Player properties
    public var playerLevel: Int16 = 1 {
        didSet { schedulePlayerUpdate() }
    }
    
    public var playerFightStyle: FightStyle? {
        didSet { schedulePlayerUpdate() }
    }
    
    public var playerFightStyleAttributes: HeroAttributes?
    public var playerLevelRandomAttributes: HeroAttributes?
    public var playerItemsAttributes: HeroAttributes?
    public var playerArmorValues: [BodyPart: Int16] = [:]
    public var playerLeftHandDamage: (minDmg: Int16, maxDmg: Int16)?
    public var playerRightHandDamage: (minDmg: Int16, maxDmg: Int16)?

    public var playerSelectedItems: [HeroItemType: UUID?] = [:] {
        didSet {
            checkPlayerTwoHandedWeapon()
            schedulePlayerItemsAttributesUpdate()
            schedulePlayerArmorUpdate()
            schedulePlayerDamageUpdate()
        }
    }

    public var playerTwoHandedWeaponId: UUID?

    // Bot properties
    public var botLevel: Int16 = 1 {
        didSet { scheduleBotUpdate() }
    }
    
    public var botFightStyle: FightStyle? {
        didSet { scheduleBotUpdate() }
    }
    
    public var botFightStyleAttributes: HeroAttributes?
    public var botLevelRandomAttributes: HeroAttributes?
    public var botItemsAttributes: HeroAttributes?
    public var botArmorValues: [BodyPart: Int16] = [:]
    public var botLeftHandDamage: (minDmg: Int16, maxDmg: Int16)?
    public var botRightHandDamage: (minDmg: Int16, maxDmg: Int16)?

    public var botSelectedItems: [HeroItemType: UUID?] = [:] {
        didSet {
            checkBotTwoHandedWeapon()
            scheduleBotItemsAttributesUpdate()
            scheduleBotArmorUpdate()
            scheduleBotDamageUpdate()
        }
    }

    public var botTwoHandedWeaponId: UUID?

    // MARK: - Computed Properties

    public var playerTotalAttributes: HeroAttributes? {
        guard let fightStyle = playerFightStyleAttributes,
              let level = playerLevelRandomAttributes else {
            return nil
        }

        let items = playerItemsAttributes ?? HeroAttributes()

        return HeroAttributes(
            hitPoints: fightStyle.hitPoints + level.hitPoints + items.hitPoints,
            manaPoints: fightStyle.manaPoints + level.manaPoints + items.manaPoints,
            agility: fightStyle.agility + level.agility + items.agility,
            strength: fightStyle.strength + level.strength + items.strength,
            power: fightStyle.power + level.power + items.power,
            instinct: fightStyle.instinct + level.instinct + items.instinct
        )
    }

    public var botTotalAttributes: HeroAttributes? {
        guard let fightStyle = botFightStyleAttributes,
              let level = botLevelRandomAttributes else {
            return nil
        }

        let items = botItemsAttributes ?? HeroAttributes()

        return HeroAttributes(
            hitPoints: fightStyle.hitPoints + level.hitPoints + items.hitPoints,
            manaPoints: fightStyle.manaPoints + level.manaPoints + items.manaPoints,
            agility: fightStyle.agility + level.agility + items.agility,
            strength: fightStyle.strength + level.strength + items.strength,
            power: fightStyle.power + level.power + items.power,
            instinct: fightStyle.instinct + level.instinct + items.instinct
        )
    }

    // MARK: - Private State

    private var playerUpdateTask: Task<Void, Never>?
    private var botUpdateTask: Task<Void, Never>?
    private var playerTwoHandedWeaponTask: Task<Void, Never>?
    private var botTwoHandedWeaponTask: Task<Void, Never>?
    private var playerItemsAttributesTask: Task<Void, Never>?
    private var botItemsAttributesTask: Task<Void, Never>?
    private var playerArmorTask: Task<Void, Never>?
    private var botArmorTask: Task<Void, Never>?
    private var playerDamageTask: Task<Void, Never>?
    private var botDamageTask: Task<Void, Never>?

    // MARK: - Hero Type Accessors

    private func level(for heroType: HeroType) -> Int16 {
        heroType == .player ? playerLevel : botLevel
    }

    private func fightStyle(for heroType: HeroType) -> FightStyle? {
        heroType == .player ? playerFightStyle : botFightStyle
    }

    private func fightStyleAttributes(for heroType: HeroType) -> HeroAttributes? {
        heroType == .player ? playerFightStyleAttributes : botFightStyleAttributes
    }

    private func setFightStyleAttributes(_ attrs: HeroAttributes?, for heroType: HeroType) {
        if heroType == .player {
            playerFightStyleAttributes = attrs
        } else {
            botFightStyleAttributes = attrs
        }
    }

    private func setLevelRandomAttributes(_ attrs: HeroAttributes?, for heroType: HeroType) {
        if heroType == .player {
            playerLevelRandomAttributes = attrs
        } else {
            botLevelRandomAttributes = attrs
        }
    }

    private func selectedItems(for heroType: HeroType) -> [HeroItemType: UUID?] {
        heroType == .player ? playerSelectedItems : botSelectedItems
    }

    private func setTwoHandedWeaponId(_ id: UUID?, for heroType: HeroType) {
        if heroType == .player {
            playerTwoHandedWeaponId = id
        } else {
            botTwoHandedWeaponId = id
        }
    }

    private func setItemsAttributes(_ attrs: HeroAttributes?, for heroType: HeroType) {
        if heroType == .player {
            playerItemsAttributes = attrs
        } else {
            botItemsAttributes = attrs
        }
    }

    private func setArmorValues(_ values: [BodyPart: Int16], for heroType: HeroType) {
        if heroType == .player {
            playerArmorValues = values
        } else {
            botArmorValues = values
        }
    }

    private func setLeftHandDamage(_ damage: (minDmg: Int16, maxDmg: Int16)?, for heroType: HeroType) {
        if heroType == .player {
            playerLeftHandDamage = damage
        } else {
            botLeftHandDamage = damage
        }
    }

    private func setRightHandDamage(_ damage: (minDmg: Int16, maxDmg: Int16)?, for heroType: HeroType) {
        if heroType == .player {
            playerRightHandDamage = damage
        } else {
            botRightHandDamage = damage
        }
    }

    // Task accessors
    private func updateTask(for heroType: HeroType) -> Task<Void, Never>? {
        heroType == .player ? playerUpdateTask : botUpdateTask
    }

    private func setUpdateTask(_ task: Task<Void, Never>?, for heroType: HeroType) {
        if heroType == .player {
            playerUpdateTask = task
        } else {
            botUpdateTask = task
        }
    }

    private func twoHandedWeaponTask(for heroType: HeroType) -> Task<Void, Never>? {
        heroType == .player ? playerTwoHandedWeaponTask : botTwoHandedWeaponTask
    }

    private func setTwoHandedWeaponTask(_ task: Task<Void, Never>?, for heroType: HeroType) {
        if heroType == .player {
            playerTwoHandedWeaponTask = task
        } else {
            botTwoHandedWeaponTask = task
        }
    }

    private func itemsAttributesTask(for heroType: HeroType) -> Task<Void, Never>? {
        heroType == .player ? playerItemsAttributesTask : botItemsAttributesTask
    }

    private func setItemsAttributesTask(_ task: Task<Void, Never>?, for heroType: HeroType) {
        if heroType == .player {
            playerItemsAttributesTask = task
        } else {
            botItemsAttributesTask = task
        }
    }

    private func armorTask(for heroType: HeroType) -> Task<Void, Never>? {
        heroType == .player ? playerArmorTask : botArmorTask
    }

    private func setArmorTask(_ task: Task<Void, Never>?, for heroType: HeroType) {
        if heroType == .player {
            playerArmorTask = task
        } else {
            botArmorTask = task
        }
    }

    private func damageTask(for heroType: HeroType) -> Task<Void, Never>? {
        heroType == .player ? playerDamageTask : botDamageTask
    }

    private func setDamageTask(_ task: Task<Void, Never>?, for heroType: HeroType) {
        if heroType == .player {
            playerDamageTask = task
        } else {
            botDamageTask = task
        }
    }

    // MARK: - Initialization

    public init(
        itemsRepository: ItemsRepository,
        attributeService: AttributeService,
        armorService: ArmorService,
        damageService: DamageService,
        weaponValidator: WeaponValidator,
        elfHeroBuilder: ElfHeroBuilder
    ) {
        self.itemsRepository = itemsRepository
        self.attributeService = attributeService
        self.armorService = armorService
        self.damageService = damageService
        self.weaponValidator = weaponValidator
        self.elfHeroBuilder = elfHeroBuilder
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
                let currentItems = heroType == .player ? self.playerSelectedItems : self.botSelectedItems
                let validatedItems = await self.weaponValidator.validateAndResolve(
                    selecting: selectedItemId,
                    for: itemType,
                    currentItems: currentItems
                )

                switch heroType {
                case .player:
                    self.playerSelectedItems = validatedItems
                case .bot:
                    self.botSelectedItems = validatedItems
                }
            }
        } else {
            // Other items don't need validation
            switch heroType {
            case .player:
                self.playerSelectedItems[itemType] = selectedItemId
            case .bot:
                self.botSelectedItems[itemType] = selectedItemId
            }
        }
    }

    private func requiresValidation(_ itemType: HeroItemType) -> Bool {
        return itemType == .weapons || itemType == .shields
    }

    private func getCurrentItemId(for heroType: HeroType, itemType: HeroItemType) -> UUID? {
        switch heroType {
        case .player:
            return playerSelectedItems[itemType] ?? nil
        case .bot:
            return botSelectedItems[itemType] ?? nil
        }
    }

    // MARK: - Generic Attribute Updates

    private func scheduleAttributesUpdate(for heroType: HeroType) {
        // Cancel previous task
        updateTask(for: heroType)?.cancel()

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

                // Fetch attributes in parallel
                let service = attributeService
                async let fightStyleAttrs = service.getAllFightStyleAttributes(
                    for: fightStyle,
                    at: currentLevel
                )
                async let levelRandomAttrs = service.getAllRandomLevelAttributes(
                    for: currentLevel
                )

                let (fsAttrs, lrAttrs) = await (fightStyleAttrs, levelRandomAttrs)

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

        setUpdateTask(task, for: heroType)
    }

    // MARK: - Player/Bot Wrapper Methods

    private func schedulePlayerUpdate() {
        scheduleAttributesUpdate(for: .player)
    }

    private func scheduleBotUpdate() {
        scheduleAttributesUpdate(for: .bot)
    }

    // MARK: - Two-Handed Weapon Checks

    private func checkTwoHandedWeapon(for heroType: HeroType) {
        // Cancel previous task
        twoHandedWeaponTask(for: heroType)?.cancel()

        // Capture current weapon ID for validation
        let currentWeaponId = selectedItems(for: heroType)[.weapons] ?? nil

        // Immediately clear if no weapon selected
        guard let weaponId = currentWeaponId else {
            setTwoHandedWeaponId(nil, for: heroType)
            return
        }

        let task = Task {
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate weapon ID hasn't changed
            guard selectedItems(for: heroType)[.weapons] == currentWeaponId else {
                return  // Value changed - this task is outdated
            }

            // Get weapon item
            guard let item = await itemsRepository.getHeroItem(weaponId),
                  let weapon = item as? WeaponItem else {
                // No weapon or not a weapon item
                setTwoHandedWeaponId(nil, for: heroType)
                return
            }

            // Final validation before updating
            guard !Task.isCancelled,
                  selectedItems(for: heroType)[.weapons] == currentWeaponId else {
                return  // Value changed during fetch
            }

            // Safe to update
            setTwoHandedWeaponId(weapon.handUse == .both ? weapon.id : nil, for: heroType)
        }

        setTwoHandedWeaponTask(task, for: heroType)
    }

    private func checkPlayerTwoHandedWeapon() {
        checkTwoHandedWeapon(for: .player)
    }

    private func checkBotTwoHandedWeapon() {
        checkTwoHandedWeapon(for: .bot)
    }

    // MARK: - Items Attributes Updates

    private func scheduleItemsAttributesUpdate(for heroType: HeroType) {
        // Cancel previous task
        itemsAttributesTask(for: heroType)?.cancel()

        // Capture current items for validation
        let currentItems = selectedItems(for: heroType)

        let task = Task {
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate items haven't changed
            guard selectedItems(for: heroType) == currentItems else {
                return  // Items changed - this task is outdated
            }

            // Extract non-nil UUIDs from items dictionary
            let itemIds = currentItems.values.compactMap { $0 }

            // Fetch items attributes
            let itemsAttrs = await attributeService.getAllItemsAttrbutes(for: itemIds)

            // Final validation before updating
            guard !Task.isCancelled,
                  selectedItems(for: heroType) == currentItems else {
                return  // Items changed during fetch
            }

            // Safe to update
            setItemsAttributes(itemsAttrs, for: heroType)
        }

        setItemsAttributesTask(task, for: heroType)
    }

    private func schedulePlayerItemsAttributesUpdate() {
        scheduleItemsAttributesUpdate(for: .player)
    }

    private func scheduleBotItemsAttributesUpdate() {
        scheduleItemsAttributesUpdate(for: .bot)
    }

    // MARK: - Armor Updates

    private func scheduleArmorUpdate(for heroType: HeroType) {
        // Cancel previous task
        armorTask(for: heroType)?.cancel()

        // Capture current items for validation
        let currentItems = selectedItems(for: heroType)

        let task = Task {
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate items haven't changed
            guard selectedItems(for: heroType) == currentItems else {
                return  // Items changed - this task is outdated
            }

            // Extract non-nil UUIDs from items dictionary
            let itemIds = currentItems.values.compactMap { $0 }

            // Fetch armor values
            let armorValues = await armorService.getAllItemsArmor(for: itemIds)

            // Final validation before updating
            guard !Task.isCancelled,
                  selectedItems(for: heroType) == currentItems else {
                return  // Items changed during fetch
            }

            // Safe to update
            setArmorValues(armorValues, for: heroType)
        }

        setArmorTask(task, for: heroType)
    }

    private func schedulePlayerArmorUpdate() {
        scheduleArmorUpdate(for: .player)
    }

    private func scheduleBotArmorUpdate() {
        scheduleArmorUpdate(for: .bot)
    }

    // MARK: - Damage Updates

    private func scheduleDamageUpdate(for heroType: HeroType) {
        // Cancel previous task
        damageTask(for: heroType)?.cancel()

        // Capture current items for validation
        let currentItems = selectedItems(for: heroType)

        let task = Task {
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate items haven't changed
            guard selectedItems(for: heroType) == currentItems else {
                return  // Items changed - this task is outdated
            }

            // Get weapon IDs
            let primaryWeaponId = currentItems[.weapons] ?? nil
            let secondaryWeaponId = currentItems[.shields] ?? nil

            // Calculate damage for each hand
            let rightHandDamage: (minDmg: Int16, maxDmg: Int16)?
            let leftHandDamage: (minDmg: Int16, maxDmg: Int16)?

            // Check if primary weapon is two-handed
            var isTwoHanded = false
            if let weaponId = primaryWeaponId,
               let item = await itemsRepository.getHeroItem(weaponId),
               let weapon = item as? WeaponItem {
                isTwoHanded = weapon.handUse == .both
            }

            if isTwoHanded {
                // Two-handed weapon: damage only in right hand, left hand is 0-0
                rightHandDamage = await damageService.getWeaponDamage(weaponId: primaryWeaponId)
                leftHandDamage = (minDmg: 0, maxDmg: 0)
            } else {
                // Single weapons: calculate separately for each hand
                rightHandDamage = await damageService.getWeaponDamage(weaponId: primaryWeaponId)
                leftHandDamage = await damageService.getWeaponDamage(weaponId: secondaryWeaponId)
            }

            // Final validation before updating
            guard !Task.isCancelled,
                  selectedItems(for: heroType) == currentItems else {
                return  // Items changed during fetch
            }

            // Safe to update
            setRightHandDamage(rightHandDamage, for: heroType)
            setLeftHandDamage(leftHandDamage, for: heroType)
        }

        setDamageTask(task, for: heroType)
    }

    private func schedulePlayerDamageUpdate() {
        scheduleDamageUpdate(for: .player)
    }

    private func scheduleBotDamageUpdate() {
        scheduleDamageUpdate(for: .bot)
    }

    // MARK: - Battle Creation

    /// Create a Battle instance from current player and bot configurations
    /// - Returns: Battle instance or nil if validation fails
    public func startBattle() async -> Battle? {
        // Validate player configuration
        guard let playerFightStyleAttrs = playerFightStyleAttributes,
              let playerLevelAttrs = playerLevelRandomAttributes else {
            return nil
        }

        // Validate bot configuration
        guard let botFightStyleAttrs = botFightStyleAttributes,
              let botLevelAttrs = botLevelRandomAttributes else {
            return nil
        }

        // Build ElfHero for player
        guard let playerHero = await elfHeroBuilder.buildElfHero(
            level: playerLevel,
            fightStyleAttributes: playerFightStyleAttrs,
            randomLevelAttributes: playerLevelAttrs,
            selectedItems: playerSelectedItems
        ) else {
            return nil
        }

        // Build ElfHero for bot
        guard let botHero = await elfHeroBuilder.buildElfHero(
            level: botLevel,
            fightStyleAttributes: botFightStyleAttrs,
            randomLevelAttributes: botLevelAttrs,
            selectedItems: botSelectedItems
        ) else {
            return nil
        }

        // Create and return Battle
        return Battle(
            leftTeam: [playerHero],
            rightTeam: [botHero]
        )
    }
}

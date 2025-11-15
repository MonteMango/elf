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

    // MARK: - Initialization

    public init(
        itemsRepository: ItemsRepository,
        attributeService: AttributeService,
        armorService: ArmorService,
        damageService: DamageService,
        weaponValidator: WeaponValidator
    ) {
        self.itemsRepository = itemsRepository
        self.attributeService = attributeService
        self.armorService = armorService
        self.damageService = damageService
        self.weaponValidator = weaponValidator
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

    // MARK: - Player Updates

    private func schedulePlayerUpdate() {
        // Cancel previous task
        playerUpdateTask?.cancel()

        // Capture current values for validation
        let currentLevel = playerLevel
        let currentStyle = playerFightStyle

        guard let fightStyle = currentStyle else {
            // Clear attributes if no fight style selected
            playerFightStyleAttributes = nil
            playerLevelRandomAttributes = nil
            return
        }

        playerUpdateTask = Task { @MainActor in
            do {
                // Debounce: Wait 250ms
                try await Task.sleep(for: .milliseconds(250))

                // Check if cancelled during sleep
                guard !Task.isCancelled else { return }

                // Validate values haven't changed during debounce
                guard self.playerLevel == currentLevel,
                      self.playerFightStyle == currentStyle else {
                    return  // Values changed - this task is outdated
                }

                // Fetch attributes in parallel
                // Capture service to avoid actor isolation issues with async let
                let service = self.attributeService
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
                      self.playerLevel == currentLevel,
                      self.playerFightStyle == currentStyle else {
                    return  // Values changed during fetch
                }

                // Safe to update
                self.playerFightStyleAttributes = fsAttrs
                self.playerLevelRandomAttributes = lrAttrs

            } catch is CancellationError {
                // Task was cancelled - this is expected
                return
            } catch {
                // Handle other errors
                print("Error updating player attributes: \(error)")
            }
        }
    }

    // MARK: - Bot Updates

    private func scheduleBotUpdate() {
        // Cancel previous task
        botUpdateTask?.cancel()

        // Capture current values for validation
        let currentLevel = botLevel
        let currentStyle = botFightStyle

        guard let fightStyle = currentStyle else {
            // Clear attributes if no fight style selected
            botFightStyleAttributes = nil
            botLevelRandomAttributes = nil
            return
        }

        botUpdateTask = Task { @MainActor in
            do {
                // Debounce: Wait 250ms
                try await Task.sleep(for: .milliseconds(250))

                // Check if cancelled during sleep
                guard !Task.isCancelled else { return }

                // Validate values haven't changed during debounce
                guard self.botLevel == currentLevel,
                      self.botFightStyle == currentStyle else {
                    return  // Values changed - this task is outdated
                }

                // Fetch attributes in parallel
                // Capture service to avoid actor isolation issues with async let
                let service = self.attributeService
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
                      self.botLevel == currentLevel,
                      self.botFightStyle == currentStyle else {
                    return  // Values changed during fetch
                }

                // Safe to update
                self.botFightStyleAttributes = fsAttrs
                self.botLevelRandomAttributes = lrAttrs

            } catch is CancellationError {
                // Task was cancelled - this is expected
                return
            } catch {
                // Handle other errors
                print("Error updating bot attributes: \(error)")
            }
        }
    }

    // MARK: - Two-Handed Weapon Checks

    private func checkPlayerTwoHandedWeapon() {
        // Cancel previous task
        playerTwoHandedWeaponTask?.cancel()

        // Capture current weapon ID for validation
        let currentWeaponId = playerSelectedItems[.weapons] ?? nil

        // Immediately clear if no weapon selected
        guard let weaponId = currentWeaponId else {
            playerTwoHandedWeaponId = nil
            return
        }

        playerTwoHandedWeaponTask = Task { @MainActor in
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate weapon ID hasn't changed
            guard playerSelectedItems[.weapons] == currentWeaponId else {
                return  // Value changed - this task is outdated
            }

            // Get weapon item
            guard let item = await itemsRepository.getHeroItem(weaponId),
                  let weapon = item as? WeaponItem else {
                // No weapon or not a weapon item
                playerTwoHandedWeaponId = nil
                return
            }

            // Final validation before updating
            guard !Task.isCancelled,
                  playerSelectedItems[.weapons] == currentWeaponId else {
                return  // Value changed during fetch
            }

            // Safe to update
            playerTwoHandedWeaponId = weapon.handUse == .both ? weapon.id : nil
        }
    }

    private func checkBotTwoHandedWeapon() {
        // Cancel previous task
        botTwoHandedWeaponTask?.cancel()

        // Capture current weapon ID for validation
        let currentWeaponId = botSelectedItems[.weapons] ?? nil

        // Immediately clear if no weapon selected
        guard let weaponId = currentWeaponId else {
            botTwoHandedWeaponId = nil
            return
        }

        botTwoHandedWeaponTask = Task { @MainActor in
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate weapon ID hasn't changed
            guard botSelectedItems[.weapons] == currentWeaponId else {
                return  // Value changed - this task is outdated
            }

            // Get weapon item
            guard let item = await itemsRepository.getHeroItem(weaponId),
                  let weapon = item as? WeaponItem else {
                // No weapon or not a weapon item
                botTwoHandedWeaponId = nil
                return
            }

            // Final validation before updating
            guard !Task.isCancelled,
                  botSelectedItems[.weapons] == currentWeaponId else {
                return  // Value changed during fetch
            }

            // Safe to update
            botTwoHandedWeaponId = weapon.handUse == .both ? weapon.id : nil
        }
    }

    // MARK: - Items Attributes Updates

    private func schedulePlayerItemsAttributesUpdate() {
        // Cancel previous task
        playerItemsAttributesTask?.cancel()

        // Capture current items for validation
        let currentItems = playerSelectedItems

        playerItemsAttributesTask = Task { @MainActor in
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate items haven't changed
            guard playerSelectedItems == currentItems else {
                return  // Items changed - this task is outdated
            }

            // Extract non-nil UUIDs from items dictionary
            let itemIds = currentItems.values.compactMap { $0 }

            // Fetch items attributes
            let itemsAttrs = await attributeService.getAllItemsAttrbutes(for: itemIds)

            // Final validation before updating
            guard !Task.isCancelled,
                  playerSelectedItems == currentItems else {
                return  // Items changed during fetch
            }

            // Safe to update
            playerItemsAttributes = itemsAttrs
        }
    }

    private func scheduleBotItemsAttributesUpdate() {
        // Cancel previous task
        botItemsAttributesTask?.cancel()

        // Capture current items for validation
        let currentItems = botSelectedItems

        botItemsAttributesTask = Task { @MainActor in
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate items haven't changed
            guard botSelectedItems == currentItems else {
                return  // Items changed - this task is outdated
            }

            // Extract non-nil UUIDs from items dictionary
            let itemIds = currentItems.values.compactMap { $0 }

            // Fetch items attributes
            let itemsAttrs = await attributeService.getAllItemsAttrbutes(for: itemIds)

            // Final validation before updating
            guard !Task.isCancelled,
                  botSelectedItems == currentItems else {
                return  // Items changed during fetch
            }

            // Safe to update
            botItemsAttributes = itemsAttrs
        }
    }

    // MARK: - Armor Updates

    private func schedulePlayerArmorUpdate() {
        // Cancel previous task
        playerArmorTask?.cancel()

        // Capture current items for validation
        let currentItems = playerSelectedItems

        playerArmorTask = Task { @MainActor in
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate items haven't changed
            guard playerSelectedItems == currentItems else {
                return  // Items changed - this task is outdated
            }

            // Extract non-nil UUIDs from items dictionary
            let itemIds = currentItems.values.compactMap { $0 }

            // Fetch armor values
            let armorValues = await armorService.getAllItemsArmor(for: itemIds)

            // Final validation before updating
            guard !Task.isCancelled,
                  playerSelectedItems == currentItems else {
                return  // Items changed during fetch
            }

            // Safe to update
            playerArmorValues = armorValues
        }
    }

    private func scheduleBotArmorUpdate() {
        // Cancel previous task
        botArmorTask?.cancel()

        // Capture current items for validation
        let currentItems = botSelectedItems

        botArmorTask = Task { @MainActor in
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate items haven't changed
            guard botSelectedItems == currentItems else {
                return  // Items changed - this task is outdated
            }

            // Extract non-nil UUIDs from items dictionary
            let itemIds = currentItems.values.compactMap { $0 }

            // Fetch armor values
            let armorValues = await armorService.getAllItemsArmor(for: itemIds)

            // Final validation before updating
            guard !Task.isCancelled,
                  botSelectedItems == currentItems else {
                return  // Items changed during fetch
            }

            // Safe to update
            botArmorValues = armorValues
        }
    }

    // MARK: - Damage Updates

    private func schedulePlayerDamageUpdate() {
        // Cancel previous task
        playerDamageTask?.cancel()

        // Capture current items for validation
        let currentItems = playerSelectedItems

        playerDamageTask = Task { @MainActor in
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate items haven't changed
            guard playerSelectedItems == currentItems else {
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
                  playerSelectedItems == currentItems else {
                return  // Items changed during fetch
            }

            // Safe to update
            playerRightHandDamage = rightHandDamage
            playerLeftHandDamage = leftHandDamage
        }
    }

    private func scheduleBotDamageUpdate() {
        // Cancel previous task
        botDamageTask?.cancel()

        // Capture current items for validation
        let currentItems = botSelectedItems

        botDamageTask = Task { @MainActor in
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate items haven't changed
            guard botSelectedItems == currentItems else {
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
                  botSelectedItems == currentItems else {
                return  // Items changed during fetch
            }

            // Safe to update
            botRightHandDamage = rightHandDamage
            botLeftHandDamage = leftHandDamage
        }
    }
}

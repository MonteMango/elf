//
//  NewBattleSetupViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import Foundation

@Observable
//@MainActor
public final class NewBattleSetupViewModel {

    // MARK: - Dependencies

    private let navigationManager: any NavigationManaging
    private let itemsRepository: ItemsRepository
    private let attributeService: AttributeService
    private let armorService: ArmorService
    private let damageService: DamageService
    private let weaponValidator: WeaponValidator

    // MARK: - State

    // Player properties
    public var playerLevel: Int16 = 1 {
        didSet { schedulePlayerUpdate() }
    }
    
    public var playerFightStyle: FightStyle? {
        didSet { schedulePlayerUpdate() }
    }
    
    public var playerFightStyleAttributes: HeroAttributes?
    public var playerLevelRandomAttributes: HeroAttributes?

    public var playerSelectedItems: [HeroItemType: UUID?] = [:] {
        didSet { checkPlayerTwoHandedWeapon() }
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

    public var botSelectedItems: [HeroItemType: UUID?] = [:] {
        didSet { checkBotTwoHandedWeapon() }
    }

    public var botTwoHandedWeaponId: UUID?

    // MARK: - Computed Properties

    public var playerTotalAttributes: HeroAttributes? {
        guard let fightStyle = playerFightStyleAttributes,
              let level = playerLevelRandomAttributes else {
            return nil
        }

        return HeroAttributes(
            hitPoints: fightStyle.hitPoints + level.hitPoints,
            manaPoints: fightStyle.manaPoints + level.manaPoints,
            agility: fightStyle.agility + level.agility,
            strength: fightStyle.strength + level.strength,
            power: fightStyle.power + level.power,
            instinct: fightStyle.instinct + level.instinct
        )
    }

    public var botTotalAttributes: HeroAttributes? {
        guard let fightStyle = botFightStyleAttributes,
              let level = botLevelRandomAttributes else {
            return nil
        }

        return HeroAttributes(
            hitPoints: fightStyle.hitPoints + level.hitPoints,
            manaPoints: fightStyle.manaPoints + level.manaPoints,
            agility: fightStyle.agility + level.agility,
            strength: fightStyle.strength + level.strength,
            power: fightStyle.power + level.power,
            instinct: fightStyle.instinct + level.instinct
        )
    }

    // MARK: - Private State

    private var playerUpdateTask: Task<Void, Never>?
    private var botUpdateTask: Task<Void, Never>?
    private var playerTwoHandedWeaponTask: Task<Void, Never>?
    private var botTwoHandedWeaponTask: Task<Void, Never>?

    // MARK: - Initialization

    public init(
        navigationManager: any NavigationManaging,
        itemsRepository: ItemsRepository,
        attributeService: AttributeService,
        armorService: ArmorService,
        damageService: DamageService,
        weaponValidator: WeaponValidator
    ) {
        self.navigationManager = navigationManager
        self.itemsRepository = itemsRepository
        self.attributeService = attributeService
        self.armorService = armorService
        self.damageService = damageService
        self.weaponValidator = weaponValidator
    }

    // MARK: - Actions

    public func backButtonAction() {
        navigationManager.pop()
    }

    public func fightButtonAction() {
        // TODO: Navigation to battleFight - will be implemented later
    }

    public func handlePlayerItemSelection(itemType: HeroItemType) {
        handleItemSelection(for: .player, itemType: itemType)
    }

    public func handleBotItemSelection(itemType: HeroItemType) {
        handleItemSelection(for: .bot, itemType: itemType)
    }

    private func handleItemSelection(for heroType: HeroType, itemType: HeroItemType) {
        let currentItemId = getCurrentItemId(for: heroType, itemType: itemType)

        navigationManager.presentModal(
            AppRoute.selectHeroItem(
                heroType: heroType,
                heroItemType: itemType,
                currentItemId: currentItemId,
                onItemSelected: { [weak self] selectedItemId in
                    self?.updateSelectedItems(
                        for: heroType,
                        itemType: itemType,
                        selectedItemId: selectedItemId
                    )
                }
            )
        )
    }

    private func updateSelectedItems(for heroType: HeroType, itemType: HeroItemType, selectedItemId: UUID?) {
        if requiresValidation(itemType) {
            Task { @MainActor in
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
                async let fightStyleAttrs = attributeService.getAllFightStyleAttributes(
                    for: fightStyle,
                    at: currentLevel
                )
                async let levelRandomAttrs = attributeService.getAllRandomLevelAttributes(
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
                async let fightStyleAttrs = attributeService.getAllFightStyleAttributes(
                    for: fightStyle,
                    at: currentLevel
                )
                async let levelRandomAttrs = attributeService.getAllRandomLevelAttributes(
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

        playerTwoHandedWeaponTask = Task { @MainActor in
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate weapon ID hasn't changed
            guard playerSelectedItems[.weapons] == currentWeaponId else {
                return  // Value changed - this task is outdated
            }

            // Get weapon item
            guard let weaponId = currentWeaponId,
                  let item = await itemsRepository.getHeroItem(weaponId),
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

        botTwoHandedWeaponTask = Task { @MainActor in
            // Check if cancelled during task creation
            guard !Task.isCancelled else { return }

            // Validate weapon ID hasn't changed
            guard botSelectedItems[.weapons] == currentWeaponId else {
                return  // Value changed - this task is outdated
            }

            // Get weapon item
            guard let weaponId = currentWeaponId,
                  let item = await itemsRepository.getHeroItem(weaponId),
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
}

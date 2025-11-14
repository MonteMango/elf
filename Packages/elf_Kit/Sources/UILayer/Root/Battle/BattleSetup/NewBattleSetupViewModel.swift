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

    // Bot properties
    public var botLevel: Int16 = 1 {
        didSet { scheduleBotUpdate() }
    }
    public var botFightStyle: FightStyle? {
        didSet { scheduleBotUpdate() }
    }
    public var botFightStyleAttributes: HeroAttributes?
    public var botLevelRandomAttributes: HeroAttributes?

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

    // MARK: - Initialization

    public init(
        navigationManager: any NavigationManaging,
        itemsRepository: ItemsRepository,
        attributeService: AttributeService,
        armorService: ArmorService,
        damageService: DamageService
    ) {
        self.navigationManager = navigationManager
        self.itemsRepository = itemsRepository
        self.attributeService = attributeService
        self.armorService = armorService
        self.damageService = damageService
    }

    // MARK: - Actions

    public func backButtonAction() {
        navigationManager.pop()
    }

    public func fightButtonAction() {
        // TODO: Navigation to battleFight - will be implemented later
        print("User lvl: \(playerLevel)")
        print("User FightStyle: \(playerFightStyle)")
        print("User FightStyle Attrs: \(playerFightStyleAttributes)")
        print("User Level Attrs: \(playerLevelRandomAttributes)")

        print("Bot lvl: \(botLevel)")
        print("Bot FightStyle: \(botFightStyle)")
        print("Bot FightStyle Attrs: \(botFightStyleAttributes)")
        print("Bot Level Attrs: \(botLevelRandomAttributes)")
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

                let (fsAttrs, lrAttrs) = try await (fightStyleAttrs, levelRandomAttrs)

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

                let (fsAttrs, lrAttrs) = try await (fightStyleAttrs, levelRandomAttrs)

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
}

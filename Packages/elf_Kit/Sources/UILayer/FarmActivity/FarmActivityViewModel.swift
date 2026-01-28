//
//  FarmActivityViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

@Observable
@MainActor
public final class FarmActivityViewModel {

    // MARK: - Dependencies

    private let gameService: any GameService
    private let farmActivityService: any FarmActivityService
    private let monsterRepository: (any MonsterRepository)?
    private let snapshotBuilder: (any CombatantSnapshotBuilder)?

    // MARK: - Unified Activity State

    public var activityState: ActivityState = .idle

    public enum ActivityState: Equatable {
        case idle
        case performing
    }

    /// Unified result for modal presentation via AppRouter
    public var activityResult: FarmActivityResult?

    // MARK: - Monster Attack State

    /// Monster that attacked during activity (nil if no attack)
    public var attackingMonster: Monster?

    /// Battle prepared for monster attack (player vs attacking monster)
    public var pendingBattle: Battle?

    /// Chance for a monster to attack during farm activity (20%)
    private let monsterAttackChance: Double = 0.20

    // MARK: - Activity

    public let activity: FarmActivity

    // MARK: - Skill Info (Delegated to Service)

    public var skillInfo: FarmSkillInfo {
        farmActivityService.getSkillInfo(for: activity, player: gameService.game.player)
    }

    // Convenience accessors for View compatibility
    public var skillTitle: String { skillInfo.title }
    public var skillLevel: Int { skillInfo.level }
    public var skillProgress: Double { skillInfo.progress }
    public var skillExpInLevel: Int { skillInfo.expInLevel }
    public var expPerLevel: Int { skillInfo.expPerLevel }

    // MARK: - Available Items (Delegated to Service)

    public var availableItems: [FarmActivityItem] {
        farmActivityService.getAvailableItems(for: activity)
    }

    // MARK: - Action

    public var actionButtonTitle: String { activity.title }
    public let actionCost: Int = 20

    public var canPerformAction: Bool {
        currentActionPoints >= actionCost
    }

    // MARK: - Warning

    public var warningText: String {
        "Monsters could attack you during \(activity.rawValue)."
    }

    // MARK: - Monster Attack Computed Properties

    /// Player's current level (determines monster level)
    private var playerLevel: Int {
        Int(gameService.game.player.level)
    }

    /// Current world (for now, always upper world)
    private var currentWorld: WorldType {
        .upper
    }

    /// Available monsters for farm activity attacks based on current world and player level
    private var availableMonsters: [Monster] {
        guard let repo = monsterRepository else { return [] }
        let monsterLevel = min(playerLevel, 3)
        return repo.getMonsters(world: currentWorld, level: monsterLevel)
    }

    // MARK: - Computed Properties

    public var currentActionPoints: Int {
        gameService.game.gameState.currentActionPoints
    }

    public var maxActionPoints: Int {
        gameService.game.gameState.maxActionPoints
    }

    public var isLastDay: Bool {
        gameService.game.gameState.isLastDay
    }

    // MARK: - Calendar Properties

    public var currentDay: GameDay {
        gameService.game.gameState.currentDay
    }

    public var upcomingDays: [GameDay] {
        gameService.game.gameState.upcomingDays
    }

    public var calendar: [GameDay] {
        gameService.game.gameState.calendar
    }

    // MARK: - Initialization

    public init(
        activity: FarmActivity,
        gameService: any GameService,
        farmActivityService: any FarmActivityService,
        monsterRepository: (any MonsterRepository)? = nil,
        snapshotBuilder: (any CombatantSnapshotBuilder)? = nil
    ) {
        self.activity = activity
        self.gameService = gameService
        self.farmActivityService = farmActivityService
        self.monsterRepository = monsterRepository
        self.snapshotBuilder = snapshotBuilder
    }

    // MARK: - Actions

    public func advanceToNextDay() {
        gameService.advanceToNextDay()
        Task(priority: .userInitiated) {
            try? await gameService.saveGame()
        }
    }

    // MARK: - Unified Activity Action

    /// Perform the current farm activity
    public func performActivity() async {
        guard canPerformAction else { return }

        // Spend action points
        gameService.spendActionPoints(actionCost)

        // Set activity state
        activityState = .performing

        // Wait 2 seconds (activity animation)
        try? await Task.sleep(for: .seconds(2))

        // Check for monster attack (20% chance)
        if await checkMonsterAttack() {
            activityState = .idle
            return
        }

        // Perform activity via service
        let result = farmActivityService.perform(
            activity: activity,
            currentLevel: skillInfo.level,
            currentExp: currentActivityExp,
            expPerLevel: skillInfo.expPerLevel
        )

        // Apply result to game state
        farmActivityService.applyResult(result, to: gameService)

        // Set result (will trigger modal presentation via onChange in View)
        activityResult = result
        activityState = .idle

        // Save game
        Task(priority: .userInitiated) {
            try? await gameService.saveGame()
        }
    }

    /// Clear activity result after modal has been presented
    public func clearActivityResult() {
        activityResult = nil
    }

    // MARK: - Private Helpers

    /// Get current exp for the active activity
    private var currentActivityExp: Int {
        switch activity {
        case .fishing:
            return gameService.game.player.fishingExp
        case .foraging:
            return gameService.game.player.foragingExp
        case .mining:
            return gameService.game.player.miningExp
        }
    }

    // MARK: - Monster Attack Actions

    /// Returns the pending battle and clears the attacking monster state
    /// - Returns: Battle instance if pending, nil otherwise
    public func startBattle() -> Battle? {
        let battle = pendingBattle
        attackingMonster = nil
        return battle
    }

    /// Called when returning from battle to clear all monster attack state
    public func onReturnFromBattle() {
        attackingMonster = nil
        pendingBattle = nil
    }

    // MARK: - Private Monster Attack Helpers

    /// Checks if a monster should attack and prepares the battle if so
    /// - Returns: true if monster attacks, false otherwise
    private func checkMonsterAttack() async -> Bool {
        guard shouldMonsterAttack(),
              let monster = availableMonsters.randomElement(),
              let snapshotBuilder = snapshotBuilder else {
            return false
        }

        // Build player snapshot
        let player = gameService.game.player
        let selectedItems: [HeroItemType: UUID?] = player.equippedItemIds.mapValues { $0 }

        guard let playerSnapshot = await snapshotBuilder.buildSnapshot(
            name: player.name,
            imageName: player.imageName,
            level: player.level,
            fightStyleAttributes: player.fightStyleAttributes,
            randomLevelAttributes: player.randomLevelAttributes,
            selectedItems: selectedItems
        ) else {
            return false
        }

        // Build monster snapshot
        let monsterSnapshot = snapshotBuilder.buildSnapshot(from: monster)

        // Create battle
        let battle = Battle(
            leftTeam: [playerSnapshot],
            rightTeam: [monsterSnapshot]
        )

        // Set state for View to react
        attackingMonster = monster
        pendingBattle = battle

        return true
    }

    /// Determines if a monster should attack based on chance
    private func shouldMonsterAttack() -> Bool {
        Double.random(in: 0..<1) < monsterAttackChance
    }
}

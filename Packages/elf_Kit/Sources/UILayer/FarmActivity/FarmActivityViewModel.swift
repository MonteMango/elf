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
    private let progressionService: any ProgressionService
    private let equipmentQueryService: any EquipmentQueryService

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

    // MARK: - Skill Info

    public var skillTitle: String = ""
    public var skillLevel: Int = 1
    public var skillProgress: Double = 0
    public var skillExpInLevel: Int = 0
    public var expPerLevel: Int = 0

    // MARK: - Available Items

    public var availableItems: [FarmActivityItem] = []

    // MARK: - Action

    public var actionButtonTitle: String { activity.title }
    public let actionCost: Int = 20

    public var canPerformAction: Bool {
        currentActionPoints >= actionCost && activityState == .idle
    }

    // MARK: - Warning

    public var warningText: String {
        "Monsters could attack you during \(activity.rawValue)."
    }

    // MARK: - Monster Attack Computed Properties

    /// Player's current level (determines monster level)
    private func playerLevel() async -> Int {
        let player = (await gameService.game).player
        return await progressionService.calculateLevel(currentExp: player.currentExp)
    }

    /// Current world (for now, always upper world)
    private var currentWorld: WorldType {
        .upper
    }

    /// Cached available monsters for farm activity attacks
    private var availableMonsters: [Monster] = []

    // MARK: - Game State

    private var game: Game

    // MARK: - Computed Properties

    public var currentActionPoints: Int {
        game.gameState.currentActionPoints
    }

    public var maxActionPoints: Int {
        game.gameState.maxActionPoints
    }

    public var isLastDay: Bool {
        game.gameState.isLastDay
    }

    // MARK: - Calendar Properties

    public var currentDay: GameDay {
        game.gameState.currentDay
    }

    public var upcomingDays: [GameDay] {
        game.gameState.upcomingDays
    }

    public var calendar: [GameDay] {
        game.gameState.calendar
    }

    // MARK: - Initialization

    public init(
        activity: FarmActivity,
        gameService: any GameService,
        farmActivityService: any FarmActivityService,
        progressionService: any ProgressionService,
        equipmentQueryService: any EquipmentQueryService,
        monsterRepository: (any MonsterRepository)? = nil,
        snapshotBuilder: (any CombatantSnapshotBuilder)? = nil
    ) {
        self.game = gameService.currentGame
        self.activity = activity
        self.gameService = gameService
        self.farmActivityService = farmActivityService
        self.progressionService = progressionService
        self.equipmentQueryService = equipmentQueryService
        self.monsterRepository = monsterRepository
        self.snapshotBuilder = snapshotBuilder
    }

    // MARK: - Game State Observation

    public func observeGameState() async {
        await loadData()
        for await game in await gameService.gameUpdates() {
            let oldExp = currentActivityExp
            self.game = game
            if currentActivityExp != oldExp {
                await updateSkillInfo()
            }
        }
    }

    // MARK: - Data Loading

    private func updateSkillInfo() async {
        let info = await farmActivityService.getSkillInfo(for: activity, player: game.player)
        skillLevel = info.level
        skillProgress = info.progress
        skillExpInLevel = info.expInLevel
        expPerLevel = info.expPerLevel
    }

    /// Loads available items, skill info, and monsters. Call from View's .task {} modifier.
    public func loadData() async {
        availableItems = await farmActivityService.getAvailableItems(for: activity)

        let info = await farmActivityService.getSkillInfo(for: activity, player: (await gameService.game).player)
        skillTitle = info.title
        skillLevel = info.level
        skillProgress = info.progress
        skillExpInLevel = info.expInLevel
        expPerLevel = info.expPerLevel

        if let repo = monsterRepository {
            let monsterLevel = min(await playerLevel(), 3)
            availableMonsters = await repo.getMonsters(world: currentWorld, level: monsterLevel)
        }
    }

    // MARK: - Actions

    public func advanceToNextDay() async {
        await gameService.advanceToNextDay()
        try? await gameService.saveGame()
    }

    // MARK: - Unified Activity Action

    // TODO: [P2] - Missing cancellation: performActivity() has 5+ suspension points without checking
    // Task.isCancelled. Operation continues after leaving screen.
    // Fix: Add try Task.checkCancellation() between suspension points.
    /// Perform the current farm activity
    public func performActivity() async {
        guard canPerformAction else { return }
        activityState = .performing

        // Spend action points
        await gameService.spendActionPoints(actionCost)

        // Wait 2 seconds (activity animation)
        try? await Task.sleep(for: .seconds(2))

        // Check for monster attack (20% chance)
        if await checkMonsterAttack() {
            activityState = .idle
            return
        }

        // Perform activity via service
        let result = await farmActivityService.perform(
            activity: activity,
            currentExp: currentActivityExp,
            expPerLevel: expPerLevel
        )

        // Apply result to game state
        switch result {
        case .fishing(let r):
            await gameService.addFishingExperience(r.skillProgress.experienceGained)
            await gameService.addFishToInventory(r.caughtFish)
        case .foraging(let r):
            await gameService.addForagingExperience(r.skillProgress.experienceGained)
            await gameService.addHerbsToInventory(r.gatheredHerbs)
        case .mining(let r):
            await gameService.addMiningExperience(r.skillProgress.experienceGained)
            await gameService.addOresToInventory(r.minedOres)
        }

        // Set result (will trigger modal presentation via onChange in View)
        activityResult = result
        activityState = .idle

        // Save game
        try? await gameService.saveGame()
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
            return game.player.fishingExp
        case .foraging:
            return game.player.foragingExp
        case .mining:
            return game.player.miningExp
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
        let player = (await gameService.game).player
        let selectedItems: [HeroItemType: UUID?] = await equipmentQueryService.equippedBaseItemIds(from: player.equipped).mapValues { $0 }

        guard let playerSnapshot = await snapshotBuilder.buildSnapshot(
            name: player.name,
            imageName: player.imageName,
            level: await progressionService.calculateLevel(currentExp: player.currentExp),
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

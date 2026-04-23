//
//  FarmActivityViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

@MainActor
@Observable
public final class FarmActivityViewModel {

    // MARK: - Dependencies

    private let gameService: any GameService

    @ObservationIgnored
    @Dependency(\.farmActivityService) private var farmActivityService

    @ObservationIgnored
    @Dependency(\.monsterRepository) private var monsterRepository

    @ObservationIgnored
    @Dependency(\.snapshotBuilder) private var snapshotBuilder

    @ObservationIgnored
    @Dependency(\.progressionService) private var progressionService

    @ObservationIgnored
    @Dependency(\.equipmentQueryService) private var equipmentQueryService

    // MARK: - Activity

    public let activity: FarmActivity

    // MARK: - Local UI State

    public var activityState: ActivityState = .idle

    public enum ActivityState: Equatable, Sendable {
        case idle
        case performing
    }

    /// Unified result for modal presentation via AppRouter
    public var activityResult: FarmActivityResult?

    /// Monster that attacked during activity (nil if no attack)
    public var attackingMonster: Monster?

    /// Battle prepared for monster attack (player vs attacking monster)
    public var pendingBattle: Battle?

    // MARK: - Constants

    /// Chance for a monster to attack during farm activity (20%)
    private let monsterAttackChance: Double = 0.20

    public var actionButtonTitle: String { activity.title }
    public let actionCost: Int = 20

    public var warningText: String {
        "Monsters could attack you during \(activity.rawValue)."
    }

    // MARK: - Derived state (computed reactively)

    public var canPerformAction: Bool {
        gameService.actionPoints.current >= actionCost && activityState == .idle
    }

    private var skillInfo: FarmSkillInfo {
        let exp: Int = switch activity {
        case .fishing: gameService.player.fishingExp
        case .foraging: gameService.player.foragingExp
        case .mining: gameService.player.miningExp
        }
        return farmActivityService.getSkillInfo(for: activity, exp: exp)
    }

    public var skillTitle: String { skillInfo.title }
    public var skillLevel: Int { skillInfo.level }
    public var skillProgress: Double { skillInfo.progress }
    public var skillExpInLevel: Int { skillInfo.expInLevel }
    public var expPerLevel: Int { skillInfo.expPerLevel }

    public var availableItems: [FarmActivityItem] {
        farmActivityService.getAvailableItems(for: activity)
    }

    /// Pool of monsters that may attack during the activity.
    private var availableMonsters: [Monster] {
        let level = min(progressionService.calculateLevel(currentExp: gameService.player.currentExp), 3)
        return monsterRepository.getMonsters(world: .upper, level: level)
    }

    // MARK: - Initialization

    public init(activity: FarmActivity, gameService: any GameService) {
        self.activity = activity
        self.gameService = gameService
    }

    // MARK: - Actions

    /// Perform the current farm activity
    public func performActivity() async {
        guard gameService.actionPoints.current >= actionCost, activityState == .idle else { return }
        guard !Task.isCancelled else { return }

        activityState = .performing

        // Point of no return: AP spent — must complete the operation
        gameService.spendActionPoints(actionCost)

        // Wait 2 seconds (activity animation)
        try? await Task.sleep(for: .seconds(2))

        // Check for monster attack (20% chance)
        if checkMonsterAttack() {
            activityState = .idle
            return
        }

        // Perform activity via service
        let result = farmActivityService.perform(
            activity: activity,
            currentExp: currentActivityExp,
            expPerLevel: expPerLevel
        )

        // Apply result to game state (sync mutations on main)
        switch result {
        case .fishing(let r):
            gameService.addFishingExperience(r.skillProgress.experienceGained)
            gameService.addFishToInventory(r.caughtFish)
        case .foraging(let r):
            gameService.addForagingExperience(r.skillProgress.experienceGained)
            gameService.addHerbsToInventory(r.gatheredHerbs)
        case .mining(let r):
            gameService.addMiningExperience(r.skillProgress.experienceGained)
            gameService.addOresToInventory(r.minedOres)
        }

        // Skip UI updates if cancelled (user left the screen)
        guard !Task.isCancelled else {
            try? await gameService.saveGame()
            return
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
            return gameService.player.fishingExp
        case .foraging:
            return gameService.player.foragingExp
        case .mining:
            return gameService.player.miningExp
        }
    }

    // MARK: - Monster Attack Actions

    /// Returns the pending battle and clears the attacking monster state
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
    private func checkMonsterAttack() -> Bool {
        guard shouldMonsterAttack(),
              let monster = availableMonsters.randomElement() else {
            return false
        }

        let player = gameService.player.snapshot()
        let selectedItems: [HeroItemType: UUID?] = equipmentQueryService.equippedBaseItemIds(from: player.equipped).mapValues { $0 }

        guard let playerSnapshot = snapshotBuilder.buildSnapshot(
            name: player.name,
            imageName: player.imageName,
            level: progressionService.calculateLevel(currentExp: player.currentExp),
            fightStyleAttributes: player.fightStyleAttributes,
            randomLevelAttributes: player.randomLevelAttributes,
            selectedItems: selectedItems
        ) else {
            return false
        }

        let monsterSnapshot = snapshotBuilder.buildSnapshot(from: monster)

        attackingMonster = monster
        pendingBattle = Battle(
            leftTeam: [playerSnapshot],
            rightTeam: [monsterSnapshot]
        )

        return true
    }

    private func shouldMonsterAttack() -> Bool {
        Double.random(in: 0..<1) < monsterAttackChance
    }
}

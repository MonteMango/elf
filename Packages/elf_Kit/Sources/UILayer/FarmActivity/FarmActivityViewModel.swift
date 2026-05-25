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

    // MARK: - Dependencies (snapshotted at init)

    private let session: GameSession
    private let farmActivityService: any FarmActivityService
    private let monsterRepository: any MonsterRepository
    private let snapshotBuilder: any CombatantSnapshotBuilder
    private let progressionService: any ProgressionService
    private let equippedSlotResolver: any HeroEquippedSlotResolver

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
        session.state.actionPoints.current >= actionCost && activityState == .idle
    }

    private var skillInfo: FarmSkillInfo {
        let exp: Int = switch activity {
        case .fishing: session.state.player.fishingExp
        case .foraging: session.state.player.foragingExp
        case .mining: session.state.player.miningExp
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
        let level = min(progressionService.calculateLevel(currentExp: session.state.player.currentExp), 3)
        return monsterRepository.getMonsters(world: .upper, level: level)
    }

    // MARK: - Initialization

    public init(activity: FarmActivity, session: GameSession) {
        @Dependency(\.farmActivityService) var farmActivityService
        @Dependency(\.monsterRepository) var monsterRepository
        @Dependency(\.snapshotBuilder) var snapshotBuilder
        @Dependency(\.progressionService) var progressionService
        @Dependency(\.equippedSlotResolver) var equippedSlotResolver
        self.farmActivityService = farmActivityService
        self.monsterRepository = monsterRepository
        self.snapshotBuilder = snapshotBuilder
        self.progressionService = progressionService
        self.equippedSlotResolver = equippedSlotResolver

        self.activity = activity
        self.session = session
    }

    // MARK: - Actions

    /// Perform the current farm activity
    public func performActivity() async {
        guard session.state.actionPoints.current >= actionCost, activityState == .idle else { return }
        guard !Task.isCancelled else { return }

        activityState = .performing

        // Point of no return: AP spent — must complete the operation
        session.spendActionPoints(actionCost)

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
            session.addFishingExperience(r.skillProgress.experienceGained)
            session.addFishToInventory(r.caughtFish)
        case .foraging(let r):
            session.addForagingExperience(r.skillProgress.experienceGained)
            session.addHerbsToInventory(r.gatheredHerbs)
        case .mining(let r):
            session.addMiningExperience(r.skillProgress.experienceGained)
            session.addOresToInventory(r.minedOres)
        }

        // Skip UI updates if cancelled (user left the screen)
        guard !Task.isCancelled else {
            try? await session.save()
            return
        }

        // Set result (will trigger modal presentation via onChange in View)
        activityResult = result
        activityState = .idle

        // Save game
        try? await session.save()
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
            return session.state.player.fishingExp
        case .foraging:
            return session.state.player.foragingExp
        case .mining:
            return session.state.player.miningExp
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

        let player = session.state.player
        let playerSnapshot = snapshotBuilder.buildSnapshot(
            elf: player,
            level: progressionService.calculateLevel(currentExp: player.currentExp),
            globalBuffs: player.globalBuffs
        )

        let monsterSnapshot = snapshotBuilder.buildSnapshot(from: monster, globalBuffs: [])

        attackingMonster = monster
        pendingBattle = Battle(
            leftTeam: [playerSnapshot],
            rightTeam: [monsterSnapshot],
            equippedItemsByCombatantId: [
                playerSnapshot.id: equippedSlotResolver.resolve(equipped: player.equipped)
            ]
        )

        return true
    }

    private func shouldMonsterAttack() -> Bool {
        Double.random(in: 0..<1) < monsterAttackChance
    }
}

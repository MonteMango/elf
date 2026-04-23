//
//  BattleFightViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import Dependencies
import Foundation

@MainActor
@Observable
public final class BattleFightViewModel {

    // MARK: - Dependencies

    @ObservationIgnored
    @Dependency(\.botAI) private var botAI

    @ObservationIgnored
    @Dependency(\.combatRoundExecutor) private var combatRoundExecutor

    @ObservationIgnored
    @Dependency(\.battleLogger) private var battleLogger

    @ObservationIgnored
    @Dependency(\.debugBattleLogger) private var debugLogger

    @ObservationIgnored
    @Dependency(\.duelPairingService) private var duelPairingService

    @ObservationIgnored
    @Dependency(\.monsterRepository) private var monsterRepository

    @ObservationIgnored
    @Dependency(\.battleResultCalculator) private var battleResultCalculator

    // Optional session context (nil for non-hunt battles like dev BattleSetup flow)
    private let gameService: (any GameService)?

    // MARK: - State

    public let battle: Battle
    public var battleEnded: Bool = false
    public private(set) var isExecutingRound: Bool = false
    private var isFinishingBattle: Bool = false

    /// Battle result for UI display (set when battle ends)
    public private(set) var battleResult: ManualBattleResult?

    // MARK: - Round State

    /// Round logs accumulated during the battle
    public private(set) var roundLog: [ManualBattleRoundLog] = []

    public var currentRoundNumber: Int {
        return roundLog.count + 1
    }

    /// Current battle round with duel pairs (owned by ViewModel, not Battle)
    public private(set) var currentBattleRound: BattleRound?

    // MARK: - Player State (Left Team - First Combatant)

    public var playerSnapshot: CombatantSnapshot {
        return battle.leftTeam[0]
    }

    public var playerCurrentHP: Int
    public var playerMaxHP: Int

    public var playerAttackPoints: Set<BodyPart> = []
    public var playerDefensePoints: Set<BodyPart> = []

    // MARK: - Bot State (Right Team - First Combatant)

    public var botSnapshot: CombatantSnapshot {
        return battle.rightTeam[0]
    }

    public var botCurrentHP: Int
    public var botMaxHP: Int

    public var botAttackPoints: Set<BodyPart> = []
    public var botDefensePoints: Set<BodyPart> = []

    // MARK: - Round Results

    public var playerLastRoundResults: [BodyPart: PointStatus] = [:]
    public var botLastRoundResults: [BodyPart: PointStatus] = [:]

    // MARK: - Initialization

    public init(battle: Battle, gameService: (any GameService)? = nil) {
        self.battle = battle
        self.gameService = gameService

        // Initialize HP values from snapshots
        let player = battle.leftTeam[0]
        self.playerMaxHP = player.maxHP
        self.playerCurrentHP = player.currentHP

        let bot = battle.rightTeam[0]
        self.botMaxHP = bot.maxHP
        self.botCurrentHP = bot.currentHP
    }

    // MARK: - Data Loading

    /// Loads initial battle data. Call from View's .task {} modifier.
    public func loadInitialData() {
        generateNewRoundPairings()
    }

    // MARK: - Player Actions

    public func togglePlayerAttackPoint(_ bodyPart: BodyPart) {
        let maxAttackPoints = playerSnapshot.attackPoints

        if playerAttackPoints.contains(bodyPart) {
            // Deselect
            playerAttackPoints.remove(bodyPart)
        } else {
            // Select if not at limit
            if playerAttackPoints.count < maxAttackPoints {
                playerAttackPoints.insert(bodyPart)
            }
        }
    }

    public func togglePlayerDefensePoint(_ bodyPart: BodyPart) {
        let maxDefensePoints = playerSnapshot.defensePoints

        if playerDefensePoints.contains(bodyPart) {
            // Deselect
            playerDefensePoints.remove(bodyPart)
        } else {
            // Select if not at limit
            if playerDefensePoints.count < maxDefensePoints {
                playerDefensePoints.insert(bodyPart)
            }
        }
    }

    public func autoFillPoints() {
        playerAttackPoints = botAI.selectAttackPoints(count: playerSnapshot.attackPoints)
        playerDefensePoints = botAI.selectDefensePoints(count: playerSnapshot.defensePoints)
    }

    // MARK: - Round Execution

    public func executeFightRound() async {
        guard !isExecutingRound else { return }
        guard playerAttackPoints.count == playerSnapshot.attackPoints else { return }
        guard playerDefensePoints.count == playerSnapshot.defensePoints else { return }

        isExecutingRound = true
        defer { isExecutingRound = false }

        // Generate bot selections using BotAI service
        botAttackPoints = botAI.selectAttackPoints(count: botSnapshot.attackPoints)
        botDefensePoints = botAI.selectDefensePoints(count: botSnapshot.defensePoints)

        // Log round start
        debugLogger.logRoundStart(
            roundNumber: currentRoundNumber,
            playerSnapshot: playerSnapshot,
            botSnapshot: botSnapshot,
            playerAttack: Array(playerAttackPoints),
            playerDefense: Array(playerDefensePoints),
            botAttack: Array(botAttackPoints),
            botDefense: Array(botDefensePoints)
        )

        let roundResult = combatRoundExecutor.executeRound(
            playerSnapshot: playerSnapshot,
            botSnapshot: botSnapshot,
            playerAttackPoints: playerAttackPoints,
            playerDefensePoints: playerDefensePoints,
            botAttackPoints: botAttackPoints,
            botDefensePoints: botDefensePoints
        )

        // Store results
        playerLastRoundResults = roundResult.playerResults
        botLastRoundResults = roundResult.botResults

        // Store old HP values for debug logging
        let playerOldHP = playerCurrentHP
        let botOldHP = botCurrentHP

        // Update HP
        playerCurrentHP = max(0, playerCurrentHP - roundResult.playerDamageTaken)
        botCurrentHP = max(0, botCurrentHP - roundResult.botDamageTaken)

        let roundLog = battleLogger.createRoundLog(
            roundNumber: currentRoundNumber,
            playerSnapshot: playerSnapshot,
            botSnapshot: botSnapshot,
            playerActions: (attack: playerAttackPoints, defense: playerDefensePoints),
            botActions: (attack: botAttackPoints, defense: botDefensePoints),
            playerResults: roundResult.playerResults,
            botResults: roundResult.botResults
        )
        self.roundLog.append(roundLog)

        debugLogger.logRoundEnd(
            roundNumber: currentRoundNumber,
            playerOldHP: playerOldHP,
            playerNewHP: playerCurrentHP,
            botOldHP: botOldHP,
            botNewHP: botCurrentHP,
            playerResults: roundResult.playerResults,
            botResults: roundResult.botResults
        )

        // Clear selections for next round
        playerAttackPoints.removeAll()
        playerDefensePoints.removeAll()
        botAttackPoints.removeAll()
        botDefensePoints.removeAll()

        // Check if battle ended
        if playerCurrentHP <= 0 || botCurrentHP <= 0 {
            battleEnded = true
        }
    }

    // MARK: - Actions

    /// Calculates battle result, applies rewards to game state, and saves
    public func finishBattle() async {
        guard battleEnded, !isFinishingBattle else { return }
        isFinishingBattle = true

        let outcome = determineBattleOutcome()
        let monster = getMonsterFromBot()
        let currentExp: Int = gameService?.player.currentExp ?? 0

        let result = battleResultCalculator.calculateResult(
            outcome: outcome,
            monster: monster,
            currentExp: currentExp
        )
        battleResult = result

        await applyBattleRewards(result: result, monster: monster)
    }

    /// Applies battle rewards to game state (XP, drops, save)
    private func applyBattleRewards(result: ManualBattleResult, monster: Monster?) async {
        guard let gameService = gameService else { return }

        // Add XP (sync — main-actor mutation)
        if result.experienceGained > 0 {
            gameService.addPlayerExperience(result.experienceGained)
        }

        // Add drops to inventory (sync)
        if let huntRewards = result.huntRewards {
            gameService.addDropsToPlayerInventory(rewards: huntRewards)
        }

        // Save game (async — file I/O on background actor)
        do {
            try await gameService.saveGame()
        } catch {
            #if DEBUG
            print("[BattleFightViewModel] Failed to save game: \(error)")
            #endif
        }
    }

    // MARK: - Private Helpers

    private func determineBattleOutcome() -> BattleOutcome {
        if playerCurrentHP > 0 && botCurrentHP <= 0 {
            return .victory
        } else if playerCurrentHP <= 0 && botCurrentHP > 0 {
            return .defeat
        } else {
            return .draw
        }
    }

    private func getMonsterFromBot() -> Monster? {
        guard let botSnapshot = battle.rightTeam.first,
              botSnapshot.combatantType == .monster else {
            return nil
        }
        return monsterRepository.getById(id: botSnapshot.sourceId)
    }

    // MARK: - Duel Pairs

    /// Generates new random pairings for the current round
    public func generateNewRoundPairings() {
        currentBattleRound = duelPairingService.createRandomPairs(
            leftTeam: battle.leftTeam,
            rightTeam: battle.rightTeam,
            roundNumber: currentRoundNumber
        )
    }

    /// Returns the left team combatants
    public var leftTeam: [CombatantSnapshot] {
        battle.leftTeam
    }

    /// Returns the right team combatants
    public var rightTeam: [CombatantSnapshot] {
        battle.rightTeam
    }
}

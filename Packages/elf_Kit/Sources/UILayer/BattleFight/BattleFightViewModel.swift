//
//  BattleFightViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import Foundation

@Observable
@MainActor
public final class BattleFightViewModel {

    // MARK: - Dependencies

    private let botAI: BotAIService
    private let combatRoundExecutor: CombatRoundExecutor
    private let battleLogger: BattleLogger
    private let debugLogger: DebugBattleLogger
    private let duelPairingService: DuelPairingService

    // MARK: - State

    public let battle: Battle
    public var battleEnded: Bool = false

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

    public init(
        battle: Battle,
        botAI: BotAIService,
        combatRoundExecutor: CombatRoundExecutor,
        battleLogger: BattleLogger,
        debugLogger: DebugBattleLogger,
        duelPairingService: DuelPairingService
    ) {
        self.battle = battle
        self.botAI = botAI
        self.combatRoundExecutor = combatRoundExecutor
        self.battleLogger = battleLogger
        self.debugLogger = debugLogger
        self.duelPairingService = duelPairingService

        // Initialize HP values from snapshots
        let player = battle.leftTeam[0]
        self.playerMaxHP = player.maxHP
        self.playerCurrentHP = player.currentHP

        let bot = battle.rightTeam[0]
        self.botMaxHP = bot.maxHP
        self.botCurrentHP = bot.currentHP

        // Generate initial round pairings
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
        // Validate player selections
        guard playerAttackPoints.count == playerSnapshot.attackPoints else {
            return
        }
        guard playerDefensePoints.count == playerSnapshot.defensePoints else {
            return
        }

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

        // Execute combat round using CombatRoundExecutor
        // Snapshots are already in Battle, no need to create them
        let roundResult = await combatRoundExecutor.executeRound(
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

        // Store old HP values for logging
        let playerOldHP = playerCurrentHP
        let botOldHP = botCurrentHP

        // Update HP
        playerCurrentHP = max(0, playerCurrentHP - roundResult.playerDamageTaken)
        botCurrentHP = max(0, botCurrentHP - roundResult.botDamageTaken)

        // Create round log using BattleLogger
        let roundLog = battleLogger.createRoundLog(
            roundNumber: currentRoundNumber,
            playerSnapshot: playerSnapshot,
            botSnapshot: botSnapshot,
            playerActions: (attack: playerAttackPoints, defense: playerDefensePoints),
            botActions: (attack: botAttackPoints, defense: botDefensePoints),
            playerResults: roundResult.playerResults,
            botResults: roundResult.botResults,
            playerOldHP: playerOldHP,
            botOldHP: botOldHP
        )
        self.roundLog.append(roundLog)

        // Log round end
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

    // MARK: - Public Helper Methods

    public func getWinner() -> String? {
        guard battleEnded else { return nil }

        if playerCurrentHP > 0 {
            return "Player"
        } else if botCurrentHP > 0 {
            return "Bot"
        } else {
            return "Draw"
        }
    }

    // MARK: - Actions

    public func finishBattle() {
        // When battle logic is implemented, call this to trigger navigation
        battleEnded = true
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

    /// Returns a combatant snapshot by ID from either team
    public func combatantSnapshot(for id: UUID) -> CombatantSnapshot? {
        if let snapshot = battle.leftTeam.first(where: { $0.id == id }) {
            return snapshot
        }
        return battle.rightTeam.first(where: { $0.id == id })
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

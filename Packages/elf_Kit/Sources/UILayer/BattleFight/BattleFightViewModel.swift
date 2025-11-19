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

    private let attributeService: AttributeService
    private let damageService: DamageService
    private let botAI: BotAIService
    private let combatCalculator: CombatCalculator
    private let battleLogger: BattleLogger
    private let debugLogger: DebugBattleLogger

    // MARK: - State

    public var battle: Battle
    public var battleEnded: Bool = false

    // MARK: - Round State

    public var currentRoundNumber: Int {
        return battle.currentRound
    }

    // MARK: - Player State (Left Team - First Hero)

    public var playerHero: ElfHero {
        return battle.leftTeam[0]
    }

    public var playerCurrentHP: Int
    public var playerMaxHP: Int

    public var playerAttackPoints: Set<BodyPart> = []
    public var playerDefensePoints: Set<BodyPart> = []

    // MARK: - Bot State (Right Team - First Hero)

    public var botHero: ElfHero {
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
        attributeService: AttributeService,
        damageService: DamageService,
        botAI: BotAIService,
        combatCalculator: CombatCalculator,
        battleLogger: BattleLogger,
        debugLogger: DebugBattleLogger
    ) {
        self.battle = battle
        self.attributeService = attributeService
        self.damageService = damageService
        self.botAI = botAI
        self.combatCalculator = combatCalculator
        self.battleLogger = battleLogger
        self.debugLogger = debugLogger

        // Initialize HP values from heroes using service
        let player = battle.leftTeam[0]
        let bot = battle.rightTeam[0]

        let playerMaxHPValue = attributeService.calculateTotalHP(from: [
            player.fightStyleAttributes,
            player.randomLevelAttributes
        ])
        let botMaxHPValue = attributeService.calculateTotalHP(from: [
            bot.fightStyleAttributes,
            bot.randomLevelAttributes
        ])

        self.playerMaxHP = playerMaxHPValue
        self.playerCurrentHP = playerMaxHPValue

        self.botMaxHP = botMaxHPValue
        self.botCurrentHP = botMaxHPValue
    }

    // MARK: - Player Actions

    public func togglePlayerAttackPoint(_ bodyPart: BodyPart) {
        let maxAttackPoints = playerHero.atackPointsAmount

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
        let maxDefensePoints = playerHero.defensePointsAmount

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

    // MARK: - Round Execution

    public func executeFightRound() async {
        // Validate player selections
        guard playerAttackPoints.count == playerHero.atackPointsAmount else {
            return
        }
        guard playerDefensePoints.count == playerHero.defensePointsAmount else {
            return
        }

        // Generate bot selections using BotAI service
        botAttackPoints = botAI.selectAttackPoints(for: botHero)
        botDefensePoints = botAI.selectDefensePoints(for: botHero)

        // Log round start
        debugLogger.logRoundStart(
            roundNumber: currentRoundNumber,
            player: playerHero,
            bot: botHero,
            playerAttack: Array(playerAttackPoints),
            playerDefense: Array(playerDefensePoints),
            botAttack: Array(botAttackPoints),
            botDefense: Array(botDefensePoints)
        )

        // Calculate round results using CombatCalculator
        let playerResults = await combatCalculator.calculatePointStatus(
            attackingPoints: botAttackPoints,
            defendingPoints: playerDefensePoints,
            attacker: botHero,
            defender: playerHero,
            attackerName: "Bot",
            defenderName: "Player"
        )

        let botResults = await combatCalculator.calculatePointStatus(
            attackingPoints: playerAttackPoints,
            defendingPoints: botDefensePoints,
            attacker: playerHero,
            defender: botHero,
            attackerName: "Player",
            defenderName: "Bot"
        )

        // Store results
        playerLastRoundResults = playerResults
        botLastRoundResults = botResults

        // Calculate damage using DamageService
        let playerDamage = damageService.calculateTotalDamage(from: playerResults)
        let botDamage = damageService.calculateTotalDamage(from: botResults)

        // Store old HP values for logging
        let playerOldHP = playerCurrentHP
        let botOldHP = botCurrentHP

        // Update HP
        playerCurrentHP = max(0, playerCurrentHP - playerDamage)
        botCurrentHP = max(0, botCurrentHP - botDamage)

        // Create round log using BattleLogger
        let roundLog = battleLogger.createRoundLog(
            roundNumber: currentRoundNumber,
            playerHero: playerHero,
            botHero: botHero,
            playerActions: (attack: playerAttackPoints, defense: playerDefensePoints),
            botActions: (attack: botAttackPoints, defense: botDefensePoints),
            playerResults: playerResults,
            botResults: botResults,
            playerOldHP: playerOldHP,
            botOldHP: botOldHP
        )

        // Add to battle log
        battle.roundLog.append(roundLog)

        // Log round end
        debugLogger.logRoundEnd(
            roundNumber: currentRoundNumber,
            playerOldHP: playerOldHP,
            playerNewHP: playerCurrentHP,
            botOldHP: botOldHP,
            botNewHP: botCurrentHP,
            playerResults: playerResults,
            botResults: botResults
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
}

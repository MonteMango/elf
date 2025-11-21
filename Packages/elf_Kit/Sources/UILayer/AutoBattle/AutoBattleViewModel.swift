//
//  AutoBattleViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation
import Observation

@Observable
@MainActor
public final class AutoBattleViewModel {

    // MARK: - Dependencies

    private let battle: Battle
    private let attributeService: AttributeService
    private let botAI: BotAIService
    private let combatCalculator: CombatCalculator
    private let damageService: DamageService
    private let statisticsParser: BattleStatisticsParser

    // MARK: - State

    /// Current progress (0.0 - 1.0)
    public private(set) var progress: Double = 0.0

    /// Is battle currently running
    public private(set) var isRunning: Bool = false

    /// Final result (available after battle completes)
    public private(set) var result: BattleResult?

    // MARK: - Initialization

    public init(
        battle: Battle,
        attributeService: AttributeService,
        botAI: BotAIService,
        combatCalculator: CombatCalculator,
        damageService: DamageService,
        statisticsParser: BattleStatisticsParser
    ) {
        self.battle = battle
        self.attributeService = attributeService
        self.botAI = botAI
        self.combatCalculator = combatCalculator
        self.damageService = damageService
        self.statisticsParser = statisticsParser
    }

    // MARK: - Public Methods

    /// Run the auto-battle and collect statistics
    public func runAutoBattle() async {
        isRunning = true
        progress = 0.0

        guard let bot1 = battle.leftTeam.first, let bot2 = battle.rightTeam.first else {
            isRunning = false
            return
        }

        let bot1MaxHP = attributeService.calculateTotalHP(from: [
            bot1.fightStyleAttributes,
            bot1.randomLevelAttributes
        ])
        let bot2MaxHP = attributeService.calculateTotalHP(from: [
            bot2.fightStyleAttributes,
            bot2.randomLevelAttributes
        ])

        var bot1HP = bot1MaxHP
        var bot2HP = bot2MaxHP
        var currentRound = 1
        var roundHistory: [AutoBattleRoundResult] = []

        // Statistics accumulators
        var bot1CritAttempts = 0
        var bot1CritSuccesses = 0
        var bot1CritMultipliers: [Double: Int] = [:]
        var bot2CritAttempts = 0
        var bot2CritSuccesses = 0
        var bot2CritMultipliers: [Double: Int] = [:]
        var bot1CritBlockBreaks = 0
        var bot2CritBlockBreaks = 0
        var bot1CritsDodged = 0
        var bot2CritsDodged = 0
        var bot1DodgeAttempts = 0
        var bot1DodgeSuccesses = 0
        var bot2DodgeAttempts = 0
        var bot2DodgeSuccesses = 0
        var bot1DamagePerRound: [Int: Int] = [:]
        var bot2DamagePerRound: [Int: Int] = [:]
        var bot1StrengthDamagePerRound: [Int: Int] = [:]
        var bot2StrengthDamagePerRound: [Int: Int] = [:]

        // Battle loop
        while bot1HP > 0 && bot2HP > 0 {
            let roundStartBot1HP = bot1HP
            let roundStartBot2HP = bot2HP

            // Bot1 selects attack and defense
            let bot1Attack = botAI.selectAttackPoints(for: bot1)
            let bot1Defense = botAI.selectDefensePoints(for: bot1)

            // Bot2 selects attack and defense
            let bot2Attack = botAI.selectAttackPoints(for: bot2)
            let bot2Defense = botAI.selectDefensePoints(for: bot2)

            // Calculate bot2 attacking bot1
            let bot1Results = await combatCalculator.calculatePointStatus(
                attackingPoints: bot2Attack,
                defendingPoints: bot1Defense,
                attacker: bot2,
                defender: bot1,
                attackerName: "Bot2",
                defenderName: "Bot1"
            )

            // Calculate bot1 attacking bot2
            let bot2Results = await combatCalculator.calculatePointStatus(
                attackingPoints: bot1Attack,
                defendingPoints: bot2Defense,
                attacker: bot1,
                defender: bot2,
                attackerName: "Bot1",
                defenderName: "Bot2"
            )

            // Calculate damage
            let bot1DamageTaken = damageService.calculateTotalDamage(from: bot1Results)
            let bot2DamageTaken = damageService.calculateTotalDamage(from: bot2Results)

            bot1HP = max(0, bot1HP - bot1DamageTaken)
            bot2HP = max(0, bot2HP - bot2DamageTaken)

            // Collect statistics using parser service
            var bot2StrengthDamageThisRound = 0
            statisticsParser.parseStatistics(
                attackingPoints: bot2Attack,
                defendingPoints: bot1Defense,
                results: bot1Results,
                attackerCritAttempts: &bot2CritAttempts,
                attackerCritSuccesses: &bot2CritSuccesses,
                attackerCritMultipliers: &bot2CritMultipliers,
                attackerCritBlockBreaks: &bot2CritBlockBreaks,
                attackerCritsDodged: &bot2CritsDodged,
                defenderDodgeAttempts: &bot1DodgeAttempts,
                defenderDodgeSuccesses: &bot1DodgeSuccesses,
                attackerStrengthDamage: &bot2StrengthDamageThisRound
            )

            var bot1StrengthDamageThisRound = 0
            statisticsParser.parseStatistics(
                attackingPoints: bot1Attack,
                defendingPoints: bot2Defense,
                results: bot2Results,
                attackerCritAttempts: &bot1CritAttempts,
                attackerCritSuccesses: &bot1CritSuccesses,
                attackerCritMultipliers: &bot1CritMultipliers,
                attackerCritBlockBreaks: &bot1CritBlockBreaks,
                attackerCritsDodged: &bot1CritsDodged,
                defenderDodgeAttempts: &bot2DodgeAttempts,
                defenderDodgeSuccesses: &bot2DodgeSuccesses,
                attackerStrengthDamage: &bot1StrengthDamageThisRound
            )

            bot1DamagePerRound[currentRound] = bot2DamageTaken
            bot2DamagePerRound[currentRound] = bot1DamageTaken
            bot1StrengthDamagePerRound[currentRound] = bot1StrengthDamageThisRound
            bot2StrengthDamagePerRound[currentRound] = bot2StrengthDamageThisRound

            // Create round result
            let roundResult = AutoBattleRoundResult(
                roundNumber: currentRound,
                bot1AttackPoints: Array(bot1Attack),
                bot1DefensePoints: Array(bot1Defense),
                bot1StartHP: roundStartBot1HP,
                bot1EndHP: bot1HP,
                bot1DamageTaken: bot1DamageTaken,
                bot1DamageDealt: bot2DamageTaken,
                bot1Results: bot1Results,
                bot2AttackPoints: Array(bot2Attack),
                bot2DefensePoints: Array(bot2Defense),
                bot2StartHP: roundStartBot2HP,
                bot2EndHP: bot2HP,
                bot2DamageTaken: bot2DamageTaken,
                bot2DamageDealt: bot1DamageTaken,
                bot2Results: bot2Results
            )

            roundHistory.append(roundResult)

            // Update progress (estimate max 50 rounds)
            currentRound += 1
            progress = min(1.0, Double(currentRound) / 50.0)

            // Small delay for UI responsiveness
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 sec
        }

        progress = 1.0

        // Determine winner
        let winner: BattleResult.Winner = bot1HP > 0 ? .bot1 : .bot2

        // Build statistics
        let statistics = BattleStatistics(
            bot1CritAttempts: bot1CritAttempts,
            bot1CritSuccesses: bot1CritSuccesses,
            bot1CritMultipliers: bot1CritMultipliers,
            bot2CritAttempts: bot2CritAttempts,
            bot2CritSuccesses: bot2CritSuccesses,
            bot2CritMultipliers: bot2CritMultipliers,
            bot1CritBlockBreaks: bot1CritBlockBreaks,
            bot2CritBlockBreaks: bot2CritBlockBreaks,
            bot1CritsDodged: bot1CritsDodged,
            bot2CritsDodged: bot2CritsDodged,
            bot1DodgeAttempts: bot1DodgeAttempts,
            bot1DodgeSuccesses: bot1DodgeSuccesses,
            bot2DodgeAttempts: bot2DodgeAttempts,
            bot2DodgeSuccesses: bot2DodgeSuccesses,
            bot1TotalDamage: bot1DamagePerRound.values.reduce(0, +),
            bot2TotalDamage: bot2DamagePerRound.values.reduce(0, +),
            bot1DamagePerRound: bot1DamagePerRound,
            bot2DamagePerRound: bot2DamagePerRound,
            bot1TotalStrengthDamage: bot1StrengthDamagePerRound.values.reduce(0, +),
            bot2TotalStrengthDamage: bot2StrengthDamagePerRound.values.reduce(0, +),
            bot1StrengthDamagePerRound: bot1StrengthDamagePerRound,
            bot2StrengthDamagePerRound: bot2StrengthDamagePerRound
        )

        // Create final result
        result = BattleResult(
            battle: battle,
            winner: winner,
            totalRounds: currentRound - 1,
            bot1FinalHP: bot1HP,
            bot2FinalHP: bot2HP,
            roundHistory: roundHistory,
            statistics: statistics
        )

        isRunning = false
    }
}

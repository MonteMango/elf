//
//  AutoBattleViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Dependencies
import Foundation
import Observation

@MainActor
@Observable
public final class AutoBattleViewModel {

    // MARK: - Dependencies (snapshotted at init)

    private let battle: Battle
    private let battleRoundRunner: any BattleRoundRunner
    private let statisticsParser: any BattleStatisticsParser

    // MARK: - State

    /// Current progress (0.0 - 1.0)
    public private(set) var progress: Double = 0.0

    /// Is battle currently running
    public private(set) var isRunning: Bool = false

    /// Final result (available after battle completes)
    public private(set) var result: BattleResult?

    // MARK: - Initialization

    public init(battle: Battle) {
        @Dependency(\.battleRoundRunner) var battleRoundRunner
        @Dependency(\.statisticsParser) var statisticsParser
        self.battleRoundRunner = battleRoundRunner
        self.statisticsParser = statisticsParser

        self.battle = battle
    }

    // MARK: - Public Methods

    /// Run the auto-battle and collect statistics.
    ///
    /// Stays on `@MainActor`: `await battleRoundRunner.runRound(...)` hops to
    /// the cooperative pool internally for combat math and back to Main for
    /// the loop body's bookkeeping. No `Task.detached` needed — each `await`
    /// yields Main to the rendering runloop between rounds.
    public func runAutoBattle() async {
        isRunning = true
        progress = 0.0

        guard let bot1Snapshot = battle.leftTeam.first else {
            isRunning = false
            return
        }
        guard let bot2Snapshot = battle.rightTeam.first else {
            isRunning = false
            return
        }

        var leftTeam: [CombatantSnapshot] = [bot1Snapshot]
        var rightTeam: [CombatantSnapshot] = [bot2Snapshot]
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
        while leftTeam[0].isAlive && rightTeam[0].isAlive {
            let synthRound = BattleRound(
                roundNumber: currentRound,
                duelPairs: [DuelPair(
                    leftCombatantId: leftTeam[0].id,
                    rightCombatantId: rightTeam[0].id
                )]
            )
            let outcome = await battleRoundRunner.runRound(
                leftTeam: leftTeam,
                rightTeam: rightTeam,
                round: synthRound,
                heroSelection: nil
            )
            leftTeam = outcome.updatedLeftTeam
            rightTeam = outcome.updatedRightTeam

            guard let pair = outcome.pairResults.first else { break }

            let bot1DamageTaken = pair.leftOldHP - pair.leftNewHP
            let bot2DamageTaken = pair.rightOldHP - pair.rightNewHP

            // Bot2 as attacker, bot1 as defender (damage taken by bot1).
            var bot2StrengthDamageThisRound = 0
            statisticsParser.parseStatistics(
                attackingPoints: pair.rightAttack,
                defendingPoints: pair.leftDefense,
                results: pair.result.playerResults,
                attackerCritAttempts: &bot2CritAttempts,
                attackerCritSuccesses: &bot2CritSuccesses,
                attackerCritMultipliers: &bot2CritMultipliers,
                attackerCritBlockBreaks: &bot2CritBlockBreaks,
                attackerCritsDodged: &bot2CritsDodged,
                defenderDodgeAttempts: &bot1DodgeAttempts,
                defenderDodgeSuccesses: &bot1DodgeSuccesses,
                attackerStrengthDamage: &bot2StrengthDamageThisRound
            )

            // Bot1 as attacker, bot2 as defender (damage taken by bot2).
            var bot1StrengthDamageThisRound = 0
            statisticsParser.parseStatistics(
                attackingPoints: pair.leftAttack,
                defendingPoints: pair.rightDefense,
                results: pair.result.botResults,
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

            let roundResult = AutoBattleRoundResult(
                roundNumber: currentRound,
                bot1AttackPoints: Array(pair.leftAttack),
                bot1DefensePoints: Array(pair.leftDefense),
                bot1StartHP: pair.leftOldHP,
                bot1EndHP: pair.leftNewHP,
                bot1DamageTaken: bot1DamageTaken,
                bot1DamageDealt: bot2DamageTaken,
                bot1Results: pair.result.playerResults,
                bot2AttackPoints: Array(pair.rightAttack),
                bot2DefensePoints: Array(pair.rightDefense),
                bot2StartHP: pair.rightOldHP,
                bot2EndHP: pair.rightNewHP,
                bot2DamageTaken: bot2DamageTaken,
                bot2DamageDealt: bot1DamageTaken,
                bot2Results: pair.result.botResults
            )
            roundHistory.append(roundResult)

            // Animate short battles too.
            progress = min(1.0, Double(currentRound) / 50.0)
            currentRound += 1
        }

        // Determine winner via shared outcome detector. `?? .draw` is a
        // defensive fallback: the loop only exits when at least one side
        // has wiped, so detectBattleOutcome returns non-nil in practice.
        let battleOutcome = detectBattleOutcome(left: leftTeam, right: rightTeam) ?? .draw
        let winner = BattleResult.Winner(from: battleOutcome)

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

        progress = 1.0
        result = BattleResult(
            battle: battle,
            winner: winner,
            totalRounds: currentRound - 1,
            bot1FinalHP: leftTeam[0].currentHP,
            bot2FinalHP: rightTeam[0].currentHP,
            roundHistory: roundHistory,
            statistics: statistics
        )
        isRunning = false
    }
}

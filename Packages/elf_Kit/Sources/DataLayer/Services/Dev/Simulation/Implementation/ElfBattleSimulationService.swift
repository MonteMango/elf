//
//  ElfBattleSimulationService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Dependencies
import Foundation

/// Default implementation of BattleSimulationService.
/// Wraps a 1v1 battle in a synthetic `BattleRound` and delegates per-round
/// mechanics to `BattleRoundRunner`. Accumulates statistics from each
/// round's `PairResult` (called twice — once per attacker direction).
public final class ElfBattleSimulationService: BattleSimulationService {

    // MARK: - Dependencies (snapshotted at init)

    private let battleRoundRunner: any BattleRoundRunner
    private let statisticsParser: any BattleStatisticsParser

    // MARK: - Initialization

    public init() {
        @Dependency(\.battleRoundRunner) var battleRoundRunner
        @Dependency(\.statisticsParser) var statisticsParser
        self.battleRoundRunner = battleRoundRunner
        self.statisticsParser = statisticsParser
    }

    // MARK: - BattleSimulationService

    public func runSingleBattle(_ battle: Battle) async -> BattleResult {
        guard let bot1Snapshot = battle.leftTeam.first else {
            fatalError("Battle must have bot1 in left team")
        }
        guard let bot2Snapshot = battle.rightTeam.first else {
            fatalError("Battle must have bot2 in right team")
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
            currentRound += 1
        }

        // Determine winner via shared outcome detector. `?? .draw` only fires
        // if the loop exited with both alive (impossible given `while` guard).
        let outcome = detectBattleOutcome(left: leftTeam, right: rightTeam) ?? .draw
        let winner = BattleResult.Winner(from: outcome)
        let bot1HP = leftTeam[0].currentHP
        let bot2HP = rightTeam[0].currentHP

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

        return BattleResult(
            battle: battle,
            winner: winner,
            totalRounds: currentRound - 1,
            bot1FinalHP: bot1HP,
            bot2FinalHP: bot2HP,
            roundHistory: roundHistory,
            statistics: statistics
        )
    }
}

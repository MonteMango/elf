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

    public func runSingleBattle(_ battle: Battle, using generator: WithRandomNumberGenerator) async -> BattleResult {
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

        // Statistics accumulators, one per side. Each accumulator collects
        // that side's OWN actions across both roles: offensive counters
        // (crit*, strength damage) fill when the side attacks — it's passed
        // as `attackerStats` — and defensive counters (dodge*) fill when the
        // same side defends — it's passed as `defenderStats`. So
        // `bot1Stats.dodgeAttempts` are bot1's own dodges, matching the
        // legacy `bot1DodgeAttempts` projection into `BattleStatistics`.
        // See the `BattleStatisticsAccumulator` doc header for the contract.
        var bot1Stats = BattleStatisticsAccumulator()
        var bot2Stats = BattleStatisticsAccumulator()
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
                heroSelection: nil,
                using: generator
            )
            leftTeam = outcome.updatedLeftTeam
            rightTeam = outcome.updatedRightTeam

            guard let pair = outcome.pairResults.first else { break }

            let bot1DamageTaken = pair.leftOldHP - pair.leftNewHP
            let bot2DamageTaken = pair.rightOldHP - pair.rightNewHP

            // Bot2 as attacker, bot1 as defender (damage taken by bot1).
            let bot2StrengthDamageThisRound = statisticsParser.parseStatistics(
                attackingPoints: pair.rightAttack,
                defendingPoints: pair.leftDefense,
                results: pair.result.playerResults,
                attackerStats: &bot2Stats,
                defenderStats: &bot1Stats
            )

            // Bot1 as attacker, bot2 as defender (damage taken by bot2).
            let bot1StrengthDamageThisRound = statisticsParser.parseStatistics(
                attackingPoints: pair.leftAttack,
                defendingPoints: pair.rightDefense,
                results: pair.result.botResults,
                attackerStats: &bot1Stats,
                defenderStats: &bot2Stats
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
            bot1CritAttempts: bot1Stats.critAttempts,
            bot1CritSuccesses: bot1Stats.critSuccesses,
            bot1CritMultipliers: bot1Stats.critMultipliers,
            bot2CritAttempts: bot2Stats.critAttempts,
            bot2CritSuccesses: bot2Stats.critSuccesses,
            bot2CritMultipliers: bot2Stats.critMultipliers,
            bot1CritBlockBreaks: bot1Stats.critBlockBreaks,
            bot2CritBlockBreaks: bot2Stats.critBlockBreaks,
            bot1CritsDodged: bot1Stats.critsDodged,
            bot2CritsDodged: bot2Stats.critsDodged,
            bot1DodgeAttempts: bot1Stats.dodgeAttempts,
            bot1DodgeSuccesses: bot1Stats.dodgeSuccesses,
            bot2DodgeAttempts: bot2Stats.dodgeAttempts,
            bot2DodgeSuccesses: bot2Stats.dodgeSuccesses,
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

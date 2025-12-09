//
//  MultiBattleViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation
import Observation

@Observable
@MainActor
public final class MultiBattleViewModel {

    // MARK: - Dependencies

    private let battle: Battle
    private let battleSimulationService: BattleSimulationService

    // MARK: - Configuration

    /// Total number of battles to run
    public let totalBattles: Int

    /// Batch size for parallel execution
    public let batchSize: Int

    // MARK: - State

    /// Current progress (0.0 - 1.0)
    public private(set) var progress: Double = 0.0

    /// Number of completed battles
    public private(set) var completedBattles: Int = 0

    /// Is running battles
    public private(set) var isRunning: Bool = false

    /// Final result (available after all battles complete)
    public private(set) var result: MultiBattleResult?

    /// Whether the current run was cancelled
    public private(set) var wasCancelled: Bool = false

    // MARK: - Private State

    /// Currently running task for cancellation support
    private var runningTask: Task<Void, Never>?

    // MARK: - Initialization

    public init(
        battle: Battle,
        battleSimulationService: BattleSimulationService,
        totalBattles: Int = 1000,
        batchSize: Int = 25
    ) {
        self.battle = battle
        self.battleSimulationService = battleSimulationService
        self.totalBattles = totalBattles
        self.batchSize = batchSize
    }

    // MARK: - Public Methods

    /// Run all battles in parallel batches
    public func runAllBattles() async {
        isRunning = true
        progress = 0.0
        completedBattles = 0
        result = nil
        wasCancelled = false

        var allResults: [BattleResult] = []
        allResults.reserveCapacity(totalBattles)

        // Run in batches
        let numberOfBatches = (totalBattles + batchSize - 1) / batchSize

        for batchIndex in 0..<numberOfBatches {
            // Check for cancellation before starting batch
            if Task.isCancelled {
                wasCancelled = true
                break
            }

            let startIndex = batchIndex * batchSize
            let endIndex = min(startIndex + batchSize, totalBattles)
            let battlesInBatch = endIndex - startIndex

            // Run batch in parallel
            let batchResults = await withTaskGroup(of: BattleResult.self) { group in
                for _ in 0..<battlesInBatch {
                    group.addTask { [self] in
                        await self.battleSimulationService.runSingleBattle(self.battle)
                    }
                }

                var results: [BattleResult] = []
                results.reserveCapacity(battlesInBatch)

                for await result in group {
                    results.append(result)
                }

                return results
            }

            allResults.append(contentsOf: batchResults)
            completedBattles = allResults.count
            progress = Double(completedBattles) / Double(totalBattles)
        }

        // If cancelled, clean up and return early
        if wasCancelled {
            isRunning = false
            return
        }

        // Calculate win/draw counts
        var bot1Wins = 0
        var bot2Wins = 0
        var draws = 0

        for battleResult in allResults {
            switch battleResult.winner {
            case .bot1:
                bot1Wins += 1
            case .bot2:
                bot2Wins += 1
            case .draw:
                draws += 1
            }
        }

        // Get bot configurations
        let bot1Level = Int(battle.leftTeam.first?.level ?? 1)
        let bot2Level = Int(battle.rightTeam.first?.level ?? 1)

        // Aggregate statistics
        let bot1Stats = AggregatedBattleStatistics.aggregate(from: allResults, forBot1: true)
        let bot2Stats = AggregatedBattleStatistics.aggregate(from: allResults, forBot1: false)

        // Create final result
        result = MultiBattleResult(
            totalBattles: totalBattles,
            bot1Level: bot1Level,
            bot2Level: bot2Level,
            bot1Wins: bot1Wins,
            bot2Wins: bot2Wins,
            draws: draws,
            battleResults: allResults,
            bot1AggregatedStats: bot1Stats,
            bot2AggregatedStats: bot2Stats
        )

        // Log results to console
        logResults()

        isRunning = false
    }

    /// Start running all battles in a cancellable task
    public func startBattles() {
        runningTask = Task {
            await runAllBattles()
        }
    }

    /// Cancel the currently running battles
    public func cancel() {
        runningTask?.cancel()
        runningTask = nil
    }

    /// Reset state for new run
    public func reset() {
        cancel()
        progress = 0.0
        completedBattles = 0
        isRunning = false
        result = nil
        wasCancelled = false
    }

    // MARK: - Private Methods

    /// Log results to console
    private func logResults() {
        guard let result = result else { return }

        print("\n========================================")
        print("\(totalBattles) AUTO BATTLE RESULTS")
        print("========================================")

        // Win rates
        let bot1WinPercent = String(format: "%.1f", result.bot1WinRate * 100)
        let bot2WinPercent = String(format: "%.1f", result.bot2WinRate * 100)
        let drawPercent = String(format: "%.1f", result.drawRate * 100)

        print("\nWIN RATES:")
        print("  Bot1 (Lv.\(result.bot1Level)): \(result.bot1Wins) wins (\(bot1WinPercent)%)")
        print("  Bot2 (Lv.\(result.bot2Level)): \(result.bot2Wins) wins (\(bot2WinPercent)%)")
        print("  Draws: \(result.draws) (\(drawPercent)%)")

        // Bot1 Statistics
        let bot1Stats = result.bot1AggregatedStats
        let bot2Stats = result.bot2AggregatedStats
        print("\nBOT1 STATISTICS:")
        print("  Avg Rounds: \(String(format: "%.1f", bot1Stats.averageRounds))")
        print("  Crit Rate: \(String(format: "%.1f", bot1Stats.averageCritRate * 100))%")
        print("  Avg Crit Hits: \(String(format: "%.1f", bot1Stats.averageCritHits))")
        print("  Crit Block Break Rate: \(String(format: "%.1f", bot1Stats.averageCritBlockBreakRate * 100))%")
        print("  Crits Dodged Rate: \(String(format: "%.1f", bot2Stats.averageCritsDodgedRate * 100))%")
        print("  Dodge Rate: \(String(format: "%.1f", bot1Stats.averageDodgeRate * 100))%")
        print("  Avg Dodges: \(String(format: "%.1f", bot1Stats.averageDodges))")
        print("  Avg Total Damage: \(String(format: "%.1f", bot1Stats.averageTotalDamage))")
        print("  Avg Damage/Round: \(String(format: "%.1f", bot1Stats.averageDamagePerRound))")
        print("  Avg Strength Damage: \(String(format: "%.1f", bot1Stats.averageStrengthDamage))")
        print("  Avg Strength/Round: \(String(format: "%.1f", bot1Stats.averageStrengthDamagePerRound))")

        // Bot2 Statistics
        print("\nBOT2 STATISTICS:")
        print("  Avg Rounds: \(String(format: "%.1f", bot2Stats.averageRounds))")
        print("  Crit Rate: \(String(format: "%.1f", bot2Stats.averageCritRate * 100))%")
        print("  Avg Crit Hits: \(String(format: "%.1f", bot2Stats.averageCritHits))")
        print("  Crit Block Break Rate: \(String(format: "%.1f", bot2Stats.averageCritBlockBreakRate * 100))%")
        print("  Crits Dodged Rate: \(String(format: "%.1f", bot1Stats.averageCritsDodgedRate * 100))%")
        print("  Dodge Rate: \(String(format: "%.1f", bot2Stats.averageDodgeRate * 100))%")
        print("  Avg Dodges: \(String(format: "%.1f", bot2Stats.averageDodges))")
        print("  Avg Total Damage: \(String(format: "%.1f", bot2Stats.averageTotalDamage))")
        print("  Avg Damage/Round: \(String(format: "%.1f", bot2Stats.averageDamagePerRound))")
        print("  Avg Strength Damage: \(String(format: "%.1f", bot2Stats.averageStrengthDamage))")
        print("  Avg Strength/Round: \(String(format: "%.1f", bot2Stats.averageStrengthDamagePerRound))")

        print("\n========================================\n")
    }
}

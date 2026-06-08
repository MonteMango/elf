//
//  MultiBattleViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Dependencies
import Foundation
import Observation

@MainActor
@Observable
public final class MultiBattleViewModel {

    // MARK: - Dependencies (snapshotted at init)

    private let battle: Battle
    private let battleSimulationService: any BattleSimulationService
    private let statisticsAggregator: any BattleStatisticsAggregator

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

    public init(battle: Battle, totalBattles: Int = 1000, batchSize: Int = 25) {
        @Dependency(\.battleSimulationService) var battleSimulationService
        @Dependency(\.statisticsAggregator) var statisticsAggregator
        self.battleSimulationService = battleSimulationService
        self.statisticsAggregator = statisticsAggregator

        self.battle = battle
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

        let numberOfBatches = (totalBattles + batchSize - 1) / batchSize
        var perfTimer = BatchPerformanceTimer(expectedBatches: numberOfBatches)
        perfTimer.start()

        for batchIndex in 0..<numberOfBatches {
            if Task.isCancelled {
                wasCancelled = true
                break
            }

            let startIndex = batchIndex * batchSize
            let endIndex = min(startIndex + batchSize, totalBattles)
            let battlesInBatch = endIndex - startIndex

            // Capture Sendable values before the group so child tasks don't hop
            // back to MainActor to read them.
            let simService = battleSimulationService
            let currentBattle = battle

            let batchStart = CFAbsoluteTimeGetCurrent()
            let batchResults = await withTaskGroup(of: BattleResult.self) { group in
                for _ in 0..<battlesInBatch {
                    group.addTask {
                        await simService.runSingleBattle(currentBattle)
                    }
                }

                var results: [BattleResult] = []
                results.reserveCapacity(battlesInBatch)

                for await result in group {
                    results.append(result)
                }

                return results
            }
            perfTimer.recordBatch(startedAt: batchStart)

            allResults.append(contentsOf: batchResults)
            completedBattles = allResults.count
            progress = Double(completedBattles) / Double(totalBattles)
        }

        perfTimer.printReport(
            label: "Battle simulation perf",
            completed: allResults.count,
            totalRequested: totalBattles,
            batchSize: batchSize,
            totalRounds: allResults.reduce(0) { $0 + $1.totalRounds }
        )

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
            case .left:
                bot1Wins += 1
            case .right:
                bot2Wins += 1
            case .draw:
                draws += 1
            }
        }

        // Get bot configurations
        let bot1Level = Int(battle.leftTeam.first?.level ?? 1)
        let bot2Level = Int(battle.rightTeam.first?.level ?? 1)

        let bot1Stats = statisticsAggregator.aggregate(from: allResults, forBot1: true)
        let bot2Stats = statisticsAggregator.aggregate(from: allResults, forBot1: false)

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

        // Balance diagnostics: EP usage + block coverage
        logBalanceDiagnostics(result: result)

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

    // Per-side block / EP diagnostics derived from `roundHistory`. Aggregation
    // lives in `BattleDiagnostics` so headless tests can reuse the same math
    // without depending on this @MainActor ViewModel.
    private func logBalanceDiagnostics(result: MultiBattleResult) {
        let bot1MaxEP = result.battleResults.first?.battle.leftTeam.first?.maxEP ?? 0
        let bot2MaxEP = result.battleResults.first?.battle.rightTeam.first?.maxEP ?? 0
        let bot1Diag = BattleDiagnostics.compute(from: result.battleResults, side: .bot1, maxEP: bot1MaxEP)
        let bot2Diag = BattleDiagnostics.compute(from: result.battleResults, side: .bot2, maxEP: bot2MaxEP)
        printSideDiagnostics(label: "BOT1 (Lv.\(result.bot1Level))", diag: bot1Diag, maxEP: bot1MaxEP, totalBattles: result.totalBattles)
        printSideDiagnostics(label: "BOT2 (Lv.\(result.bot2Level))", diag: bot2Diag, maxEP: bot2MaxEP, totalBattles: result.totalBattles)
    }

    private func printSideDiagnostics(label: String, diag: BattleDiagnostics, maxEP: Int, totalBattles: Int) {
        let n = Double(max(totalBattles, 1))
        // NSLog so the output reaches the unified system log (`xcrun simctl
        // spawn booted log stream`). Plain `print` only goes to stdout, which
        // the simulator's log stream does not capture.
        NSLog("ELFBAL — %@ — BLOCK / EP DIAGNOSTICS:", label)
        NSLog("ELFBAL   Max EP available:           %d", maxEP)
        NSLog("ELFBAL   Avg EP spent / battle:      %.0f  (%.1f%% of pool)",
              Double(diag.totalEPSpent) / n,
              Double(diag.totalEPSpent) / n / Double(max(maxEP, 1)) * 100)
        NSLog("ELFBAL   Avg blocks used / battle:   %.2f  (block actually consumed EP)",
              Double(diag.totalBlocksUsed) / n)
        NSLog("ELFBAL   Avg blocks chosen / battle: %.2f  (block-points selected)",
              Double(diag.totalBlocksDefended) / n)
        NSLog("ELFBAL   Block coverage rate:        %.1f%%  (used / incoming attacks)",
              Double(diag.totalBlocksUsed) / Double(max(diag.totalAttacksLanded, 1)) * 100)
        NSLog("ELFBAL   Battles where EP ran out:   %d  (%.1f%% of battles)",
              diag.battlesExhausted,
              Double(diag.battlesExhausted) / n * 100)
        // Soft EP-exhaustion = at least one round where the side tried to
        // block but currentEP < blockCost, so the block resolved as undefended.
        NSLog("ELFBAL   Battles w/ block-fail (soft):%d  (%.1f%% of battles)",
              diag.battlesWithBlockFailure,
              Double(diag.battlesWithBlockFailure) / n * 100)
        if !diag.firstFailures.isEmpty {
            let avgRound = Double(diag.firstFailures.map(\.round).reduce(0, +)) / Double(diag.firstFailures.count)
            let avgPct = diag.firstFailures.map(\.percent).reduce(0, +) / Double(diag.firstFailures.count) * 100
            NSLog("ELFBAL   Avg round of first fail:    %.1f", avgRound)
            NSLog("ELFBAL   Avg %% through battle at fail: %.1f%%  (round / total rounds)", avgPct)
        }
    }

}

// MARK: - Perf measurement helper

/// Collects per-batch wall-clock durations during a `MultiBattleViewModel.runAllBattles`
/// execution and prints a formatted summary. Dev-only.
private struct BatchPerformanceTimer {
    private let expectedBatches: Int
    private var runStart: CFAbsoluteTime = 0
    private var batchDurations: [Double] = []

    init(expectedBatches: Int) {
        self.expectedBatches = expectedBatches
        batchDurations.reserveCapacity(expectedBatches)
    }

    mutating func start() {
        runStart = CFAbsoluteTimeGetCurrent()
        batchDurations.removeAll(keepingCapacity: true)
    }

    mutating func recordBatch(startedAt: CFAbsoluteTime) {
        batchDurations.append(CFAbsoluteTimeGetCurrent() - startedAt)
    }

    func printReport(
        label: String,
        completed: Int,
        totalRequested: Int,
        batchSize: Int,
        totalRounds: Int
    ) {
        let totalDuration = CFAbsoluteTimeGetCurrent() - runStart
        let avgBatch = batchDurations.isEmpty ? 0 : batchDurations.reduce(0, +) / Double(batchDurations.count)
        let minBatch = batchDurations.min() ?? 0
        let maxBatch = batchDurations.max() ?? 0
        let perBattle = completed > 0 ? totalDuration / Double(completed) * 1000 : 0
        let avgRounds = completed > 0 ? Double(totalRounds) / Double(completed) : 0

        print(String(format: """

        ┌─── 🏁 %@ ───────────────────────────
        │ Battles:      %d completed / %d requested
        │ Batches:      %d × batchSize=%d
        │ Total:        %.3fs
        │ Per battle:   %.3f ms
        │ Avg rounds:   %.1f per battle (total %d)
        │ Per batch:    avg=%.3fs  min=%.3fs  max=%.3fs
        │ Cores:        %d active (ProcessInfo.activeProcessorCount)
        └─────────────────────────────────────────────────────────

        """,
        label,
        completed, totalRequested,
        batchDurations.count, batchSize,
        totalDuration, perBattle,
        avgRounds, totalRounds,
        avgBatch, minBatch, maxBatch,
        ProcessInfo.processInfo.activeProcessorCount))
    }
}

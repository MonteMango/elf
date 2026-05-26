//
//  BattleSimulationIntegrationTests.swift
//  battle_simulation_IntegrationTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation
import XCTest
import os.log
@testable import elf_Kit

/// Headless replacement for the manual `BattleSetupScreen` × `1000x` sweep
/// used to validate the style triangle. Mirrors the deterministic setup the
/// dev screen uses: Recruit's Spear loadout, `includeRandomAttributes = off`,
/// no global buffs.
///
/// Lives in a dedicated `battle_simulation_IntegrationTests` target so it is
/// **not** part of the default unit-test test plan (`elf_Kit_UnitTests`). To
/// run, switch to the `battle_simulation_IntegrationTests` test plan in
/// Xcode, or pass `-testPlan battle_simulation_IntegrationTests` to
/// `xcodebuild test`.
///
/// Each full pass is 12 configs × 30 000 battles = 360 000 battles, ~2.5 min
/// wall clock on Apple silicon. Heavy by design — used for manual balance
/// analysis, not regression-gating in CI.
@MainActor
final class BattleSimulationIntegrationTests: XCTestCase {

    private let battleCount = 30_000
    private let batchSize = 25
    private let levels: [Int] = [3, 6, 9, 12]
    private let matchups: [Matchup] = [
        Matchup(name: "def_vs_crit",   h1: .def,   h2: .crit),
        Matchup(name: "def_vs_dodge",  h1: .def,   h2: .dodge),
        Matchup(name: "dodge_vs_crit", h1: .dodge, h2: .crit),
    ]

    override func setUp() async throws {
        // Mirror DependencyBootstrap.run() — game data is async-loaded from
        // resources and `ItemsRepository` etc. assert on it being registered
        // before any @Dependency access. We load JSON via the host filesystem
        // (the production DataLoader uses Bundle.main which is the xctest
        // binary in tests and doesn't carry the elf app's resources).
        let gameData = await withDependencies {
            $0.context = .live
            $0.dataLoader = ProjectResourcesDataLoader()
        } operation: {
            await DefaultGameDataRepository()
        }
        prepareDependencies {
            $0.context = .live
            $0.dataLoader = ProjectResourcesDataLoader()
            $0.gameDataRepository = gameData
            $0.itemsRepository = gameData.items
            $0.monsterRepository = gameData.monsters
            $0.fishRepository = gameData.fish
            $0.herbRepository = gameData.herbs
            $0.oreRepository = gameData.ores
            $0.materialRepository = gameData.materials
            $0.recipeRepository = gameData.recipes
            $0.questRepository = gameData.quests
            $0.dungeonRepository = gameData.dungeons
            $0.buffsRepository = gameData.buffs
        }
    }

    func testStyleTriangleSweep() async {
        // swift-dependencies normally blocks live implementations in tests.
        // For this integration test we explicitly run inside `.live` context
        // so all the real services (AttributeService, ItemsRepository,
        // CombatantSnapshotBuilder, BattleSimulationService) resolve to their
        // production impls.
        await withDependencies {
            $0.context = .live
        } operation: {
            await runSweep()
        }
    }

    private func runSweep() async {
        @Dependency(\.attributeService)        var attributeService
        @Dependency(\.itemsRepository)         var itemsRepository
        @Dependency(\.snapshotBuilder)         var snapshotBuilder
        @Dependency(\.battleSimulationService) var simService

        var rows: [SweepRow] = []
        let sweepStart = Date()
        for level in levels {
            for matchup in matchups {
                let configStart = Date()
                let h1 = makeSnapshot(
                    style: matchup.h1, level: level, name: "H1",
                    attributeService: attributeService,
                    itemsRepository: itemsRepository,
                    builder: snapshotBuilder
                )
                let h2 = makeSnapshot(
                    style: matchup.h2, level: level, name: "H2",
                    attributeService: attributeService,
                    itemsRepository: itemsRepository,
                    builder: snapshotBuilder
                )
                let battle = Battle(leftTeam: [h1], rightTeam: [h2])
                let results = await runBattles(count: battleCount, battle: battle, service: simService)
                let row = aggregate(level: level, matchup: matchup, results: results)
                rows.append(row)
                let elapsed = Date().timeIntervalSince(configStart)
                print(String(format: "  • L%d %@ done — %.1fs (%d battles)",
                             level, matchup.name, elapsed, results.count))
            }
        }
        let totalElapsed = Date().timeIntervalSince(sweepStart)
        printSummary(rows: rows, totalElapsed: totalElapsed)
    }

    // MARK: - Hero construction

    private func makeSnapshot(
        style: FightStyle,
        level: Int,
        name: String,
        attributeService: any AttributeService,
        itemsRepository: any ItemsRepository,
        builder: any CombatantSnapshotBuilder
    ) -> CombatantSnapshot {
        let fightStyleAttrs = attributeService.getAllFightStyleAttributes(for: style, at: Int16(level))
        // includeRandomAttributes = off → no random per-level roll.
        let randomLevelAttrs = HeroAttributes()
        // Empty state → makeEquipped falls back to Recruit's Spear, no armor —
        // identical to the dev BattleSetupScreen's default.
        let equipped = HeroConfigurationState(level: level).makeEquipped(itemsRepository: itemsRepository)
        return builder.buildSnapshot(
            name: name,
            imageName: "",
            level: level,
            fightStyleAttributes: fightStyleAttrs,
            randomLevelAttributes: randomLevelAttrs,
            equipped: equipped,
            globalBuffs: []
        )
    }

    // MARK: - Parallel battle runner (mirrors MultiBattleViewModel.runAllBattles)

    private func runBattles(
        count: Int,
        battle: Battle,
        service: any BattleSimulationService
    ) async -> [BattleResult] {
        var allResults: [BattleResult] = []
        allResults.reserveCapacity(count)
        let numberOfBatches = (count + batchSize - 1) / batchSize
        for batchIndex in 0..<numberOfBatches {
            let startIndex = batchIndex * batchSize
            let endIndex = min(startIndex + batchSize, count)
            let battlesInBatch = endIndex - startIndex
            let batchResults = await withTaskGroup(of: BattleResult.self) { group in
                for _ in 0..<battlesInBatch {
                    group.addTask { await service.runSingleBattle(battle) }
                }
                var results: [BattleResult] = []
                results.reserveCapacity(battlesInBatch)
                for await result in group {
                    results.append(result)
                }
                return results
            }
            allResults.append(contentsOf: batchResults)
        }
        return allResults
    }

    // MARK: - Aggregation

    private func aggregate(level: Int, matchup: Matchup, results: [BattleResult]) -> SweepRow {
        var h1Wins = 0
        var h2Wins = 0
        var draws = 0
        var totalRounds = 0
        // Strength damage (raw roll from `getRandomStrengthDamage`, before
        // armor/crit) is already aggregated per battle in `BattleStatistics`.
        // We sum across the matchup so the sweep summary can show how much of
        // total damage output is contributed by the Strength stat.
        var bot1StrengthDamage = 0
        var bot2StrengthDamage = 0
        var bot1TotalDamage = 0
        var bot2TotalDamage = 0
        var bot1CritAttempts = 0
        var bot1CritSuccesses = 0
        var bot2CritAttempts = 0
        var bot2CritSuccesses = 0
        var bot1DodgeAttempts = 0
        var bot1DodgeSuccesses = 0
        var bot2DodgeAttempts = 0
        var bot2DodgeSuccesses = 0
        for r in results {
            switch r.winner {
            case .left:  h1Wins += 1
            case .right: h2Wins += 1
            case .draw:  draws  += 1
            }
            totalRounds += r.totalRounds
            bot1StrengthDamage += r.statistics.bot1TotalStrengthDamage
            bot2StrengthDamage += r.statistics.bot2TotalStrengthDamage
            bot1TotalDamage += r.statistics.bot1TotalDamage
            bot2TotalDamage += r.statistics.bot2TotalDamage
            bot1CritAttempts += r.statistics.bot1CritAttempts
            bot1CritSuccesses += r.statistics.bot1CritSuccesses
            bot2CritAttempts += r.statistics.bot2CritAttempts
            bot2CritSuccesses += r.statistics.bot2CritSuccesses
            bot1DodgeAttempts += r.statistics.bot1DodgeAttempts
            bot1DodgeSuccesses += r.statistics.bot1DodgeSuccesses
            bot2DodgeAttempts += r.statistics.bot2DodgeAttempts
            bot2DodgeSuccesses += r.statistics.bot2DodgeSuccesses
        }
        let n = max(results.count, 1)
        let maxEP = results.first?.battle.leftTeam.first?.maxEP ?? 0
        let bot1Diag = BattleDiagnostics.compute(from: results, side: .bot1, maxEP: maxEP)
        let bot2Diag = BattleDiagnostics.compute(from: results, side: .bot2, maxEP: maxEP)
        return SweepRow(
            level: level,
            matchup: matchup,
            totalBattles: results.count,
            h1Wins: h1Wins, h2Wins: h2Wins, draws: draws,
            avgRounds: Double(totalRounds) / Double(n),
            maxEP: maxEP,
            bot1: bot1Diag,
            bot2: bot2Diag,
            bot1TotalStrengthDamage: bot1StrengthDamage,
            bot2TotalStrengthDamage: bot2StrengthDamage,
            bot1TotalDamage: bot1TotalDamage,
            bot2TotalDamage: bot2TotalDamage,
            bot1CritAttempts: bot1CritAttempts,
            bot1CritSuccesses: bot1CritSuccesses,
            bot2CritAttempts: bot2CritAttempts,
            bot2CritSuccesses: bot2CritSuccesses,
            bot1DodgeAttempts: bot1DodgeAttempts,
            bot1DodgeSuccesses: bot1DodgeSuccesses,
            bot2DodgeAttempts: bot2DodgeAttempts,
            bot2DodgeSuccesses: bot2DodgeSuccesses
        )
    }

    // MARK: - Console output

    private func printSummary(rows: [SweepRow], totalElapsed: TimeInterval) {
        let line = String(repeating: "=", count: 130)
        print()
        print(line)
        print(" Battle Simulation Sweep — \(battleCount) battles × \(levels.count) levels × \(matchups.count) matchups")
        print(String(format: " Total wall clock: %.1fs", totalElapsed))
        print(line)
        print()
        // Column reference (per-side row):
        //   Win%     — battles won by this side.
        //   EP%      — avg EP spent per battle / max EP.
        //   Blocks   — avg full blocks per battle (incl. crits that broke
        //              block but still cost EP).
        //   WkBlock  — avg weak blocks per battle (Exhausted-EP=0 path).
        //   Exh%     — battles where this side fully drained EP (the
        //              `Exhausted` debuff was applied at least once).
        //   EndRed%  — share of incoming damage absorbed by Endurance:
        //              totalEnduranceReduction / (it + totalDamageReceived).
        //   Crit%    — offensive crit success rate: this side's
        //              critSuccesses / critAttempts.
        //   Dodge%   — defensive dodge success rate: this side's
        //              dodgeSuccesses / dodgeAttempts.
        //   StrDmg   — avg raw Strength damage rolled by this side per battle
        //              (pre-armor, pre-crit bonus).
        //   Str%     — strength damage / total damage dealt by this side.
        print(padRight("Level", 7)
              + padRight("Matchup", 16)
              + padRight("Side", 8)
              + padRight("Win%", 8)
              + padRight("EP%", 8)
              + padRight("Blocks", 8)
              + padRight("WkBlock", 9)
              + padRight("Exh%", 8)
              + padRight("EndRed%", 9)
              + padRight("Crit%", 8)
              + padRight("Dodge%", 8)
              + padRight("StrDmg", 10)
              + padRight("Str%", 8))
        print(String(repeating: "-", count: 130))
        for row in rows {
            let (h1Style, h2Style) = (row.matchup.h1, row.matchup.h2)
            let n = Double(max(row.totalBattles, 1))
            let h1Win = Double(row.h1Wins) / n * 100
            let h2Win = Double(row.h2Wins) / n * 100
            let drawPct = Double(row.draws) / n * 100
            printSideRow(level: row.level, matchup: row.matchup.name, side: styleName(h1Style),
                         winPct: h1Win, diag: row.bot1, maxEP: row.maxEP, totalBattles: row.totalBattles,
                         totalStrengthDamage: row.bot1TotalStrengthDamage,
                         totalDamage: row.bot1TotalDamage,
                         critAttempts: row.bot1CritAttempts, critSuccesses: row.bot1CritSuccesses,
                         dodgeAttempts: row.bot1DodgeAttempts, dodgeSuccesses: row.bot1DodgeSuccesses)
            printSideRow(level: row.level, matchup: row.matchup.name, side: styleName(h2Style),
                         winPct: h2Win, diag: row.bot2, maxEP: row.maxEP, totalBattles: row.totalBattles,
                         totalStrengthDamage: row.bot2TotalStrengthDamage,
                         totalDamage: row.bot2TotalDamage,
                         critAttempts: row.bot2CritAttempts, critSuccesses: row.bot2CritSuccesses,
                         dodgeAttempts: row.bot2DodgeAttempts, dodgeSuccesses: row.bot2DodgeSuccesses)
            print(padRight("", 7)
                  + padRight("(draw)", 16)
                  + padRight("—", 8)
                  + String(format: "%5.1f%%", drawPct)
                  + "   avg rounds="
                  + String(format: "%.1f", row.avgRounds))
            print()
        }
        print(line)
    }

    private func printSideRow(
        level: Int, matchup: String, side: String, winPct: Double,
        diag: BattleDiagnostics, maxEP: Int, totalBattles: Int,
        totalStrengthDamage: Int, totalDamage: Int,
        critAttempts: Int, critSuccesses: Int,
        dodgeAttempts: Int, dodgeSuccesses: Int
    ) {
        let n = Double(max(totalBattles, 1))
        let epPct = Double(diag.totalEPSpent) / n / Double(max(maxEP, 1)) * 100
        let avgBlocks = Double(diag.totalBlocksUsed) / n
        let avgWeakBlocks = Double(diag.totalWeakBlocksUsed) / n
        let exhaustedPct = Double(diag.battlesExhausted) / n * 100

        // Share of incoming damage absorbed by Endurance. Denominator is the
        // "would-have-been damage" before endurance subtracted anything:
        // received + reduction. `—` when this side never took a hit.
        let endRedStr: String
        let incoming = diag.totalDamageReceived + diag.totalEnduranceReduction
        if incoming > 0 {
            let pct = Double(diag.totalEnduranceReduction) / Double(incoming) * 100
            endRedStr = String(format: "%5.1f%%", pct)
        } else {
            endRedStr = "—"
        }

        // Offensive crit rate / defensive dodge rate — `—` when the side never
        // got to attempt one (avoids div/0 and a misleading "0.0 %").
        let critRateStr: String
        if critAttempts > 0 {
            critRateStr = String(format: "%5.1f%%", Double(critSuccesses) / Double(critAttempts) * 100)
        } else {
            critRateStr = "—"
        }
        let dodgeRateStr: String
        if dodgeAttempts > 0 {
            dodgeRateStr = String(format: "%5.1f%%", Double(dodgeSuccesses) / Double(dodgeAttempts) * 100)
        } else {
            dodgeRateStr = "—"
        }

        let avgStrengthDamage = Double(totalStrengthDamage) / n
        let strengthShareStr: String
        if totalDamage > 0 {
            let pct = Double(totalStrengthDamage) / Double(totalDamage) * 100
            strengthShareStr = String(format: "%5.1f%%", pct)
        } else {
            strengthShareStr = "—"
        }
        print(padRight("L\(level)", 7)
              + padRight(matchup, 16)
              + padRight(side, 8)
              + String(format: "%5.1f%% ", winPct)
              + String(format: "%5.1f%% ", epPct)
              + String(format: "%5.2f   ", avgBlocks)
              + padRight(String(format: "%5.2f", avgWeakBlocks), 9)
              + String(format: "%5.1f%% ", exhaustedPct)
              + padRight(endRedStr, 9)
              + padRight(critRateStr, 8)
              + padRight(dodgeRateStr, 8)
              + padRight(String(format: "%6.1f", avgStrengthDamage), 10)
              + padRight(strengthShareStr, 8))
    }

    private func padRight(_ s: String, _ width: Int) -> String {
        if s.count >= width { return s }
        return s + String(repeating: " ", count: width - s.count)
    }

    private func styleName(_ s: FightStyle) -> String {
        switch s {
        case .def: return "def"
        case .crit: return "crit"
        case .dodge: return "dodge"
        }
    }

    // MARK: - Models

    private struct Matchup {
        let name: String
        let h1: FightStyle
        let h2: FightStyle
    }

    private struct SweepRow {
        let level: Int
        let matchup: Matchup
        let totalBattles: Int
        let h1Wins: Int
        let h2Wins: Int
        let draws: Int
        let avgRounds: Double
        let maxEP: Int
        let bot1: BattleDiagnostics
        let bot2: BattleDiagnostics
        let bot1TotalStrengthDamage: Int
        let bot2TotalStrengthDamage: Int
        let bot1TotalDamage: Int
        let bot2TotalDamage: Int
        // Crit / dodge raw counters (offensive crit for this side, defensive
        // dodge for this side). Used to compute success-rate columns
        // `Crit%` / `Dodge%`.
        let bot1CritAttempts: Int
        let bot1CritSuccesses: Int
        let bot2CritAttempts: Int
        let bot2CritSuccesses: Int
        let bot1DodgeAttempts: Int
        let bot1DodgeSuccesses: Int
        let bot2DodgeAttempts: Int
        let bot2DodgeSuccesses: Int
    }
}

/// Loads JSON resources from the elf iOS-app target's `Resources/` directory.
/// Production `ElfDataLoader` reads `Bundle.main`, which in tests is the xctest
/// binary — that bundle doesn't carry the app's game-data JSON. We resolve
/// project root relative to this source file (`#filePath`) so the path is
/// portable across developer machines without per-host configuration.
private struct ProjectResourcesDataLoader: DataLoader {

    private let resourcesURL: URL

    init(file: String = #filePath) {
        let testFile = URL(fileURLWithPath: file)
        // Path: <project-root>/Packages/elf_Kit/Tests/battle_simulation_IntegrationTests/<this file>
        // → climb 5 directories up to project root.
        let projectRoot = testFile
            .deletingLastPathComponent()   // battle_simulation_IntegrationTests/
            .deletingLastPathComponent()   // Tests/
            .deletingLastPathComponent()   // elf_Kit/
            .deletingLastPathComponent()   // Packages/
            .deletingLastPathComponent()   // project root
        self.resourcesURL = projectRoot.appendingPathComponent("elf/Resources")
    }

    func loadJSON(_ resourceName: String) async throws -> Data {
        let url = resourcesURL.appendingPathComponent("\(resourceName).json")
        return try Data(contentsOf: url)
    }

    func loadAndDecode<T: Decodable>(
        resourceName: String,
        fallback: @autoclosure () -> T,
        log: OSLog
    ) async -> T {
        do {
            let data = try await loadJSON(resourceName)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            os_log("ProjectResourcesDataLoader failed to load %{public}@.json: %{public}@",
                   log: log, type: .error, resourceName, error.localizedDescription)
            return fallback()
        }
    }
}

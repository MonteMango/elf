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

    /// Acceptance gate for the per-battle RNG threading: the same seeded
    /// generator must reproduce a battle byte-for-byte (proves the generator
    /// reaches every roll site), and a different seed must (almost surely)
    /// diverge (proves the seed actually drives the rolls).
    func testPerBattleSeed_IsReproducibleAndSeedDependent() async {
        await withDependencies {
            $0.context = .live
        } operation: {
            @Dependency(\.attributeService)        var attributeService
            @Dependency(\.itemsRepository)         var itemsRepository
            @Dependency(\.snapshotBuilder)         var snapshotBuilder
            @Dependency(\.battleSimulationService) var simService

            let h1 = makeSnapshot(
                style: .crit, level: 12, name: "H1",
                attributeService: attributeService, itemsRepository: itemsRepository, builder: snapshotBuilder
            )
            let h2 = makeSnapshot(
                style: .def, level: 12, name: "H2",
                attributeService: attributeService, itemsRepository: itemsRepository, builder: snapshotBuilder
            )
            let battle = Battle(leftTeam: [h1], rightTeam: [h2])

            func fingerprint(seed: UInt64) async -> [Int] {
                let gen = WithRandomNumberGenerator(SeededRandomNumberGenerator(seed: seed))
                let r = await simService.runSingleBattle(battle, using: gen)
                let winnerCode: Int = { switch r.winner { case .left: return 0; case .right: return 1; case .draw: return 2 } }()
                return [winnerCode, r.totalRounds, r.statistics.bot1TotalDamage, r.statistics.bot2TotalDamage]
            }

            let a = await fingerprint(seed: 42)
            let b = await fingerprint(seed: 42)
            XCTAssertEqual(a, b, "Same seed must reproduce the battle exactly")

            let c = await fingerprint(seed: 99)
            XCTAssertNotEqual(a, c, "Different seed should (almost surely) diverge")
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

    /// Random-attributes variant of `testStyleTriangleSweep`. Instead of one
    /// pristine snapshot per matchup, each individual battle gets fresh
    /// random-level-attribute rolls (`getAllRandomLevelAttributes` =
    /// `+4 points × level` distributed across agi/str/pow/int/end) for both
    /// heroes. Closer to real-play variability — players don't all have
    /// identical stat profiles at a given level.
    func testStyleTriangleSweepWithRandomAttributes() async {
        await withDependencies {
            $0.context = .live
        } operation: {
            await runRandomSweep()
        }
    }

    /// Attribute-value probe — **not** a triangle test. Builds "champion"
    /// elves that each dump an equal stat budget into a single attribute (or
    /// a 2-stat combo), all sharing the same HP and weapon, then runs a full
    /// round-robin duel matrix. The point is to isolate *how much raw combat
    /// value each attribute point is worth*, surface dead/over-powered stats,
    /// and flag any "goat" stat-stacking build. Pure analysis — drives no
    /// balance change on its own.
    func testAttributeValueMatrix() async {
        await withDependencies {
            $0.context = .live
        } operation: {
            await runAttributeMatrix()
        }
    }

    /// "If the player could choose where to spend the +4/level random pool,
    /// what's the best strategy per fight style?" Builds each style with
    /// 7 distinct strategies for the bonus pool (all-into-one-stat, STR+END
    /// combo, random baseline), pits each variant against the other two
    /// classes built with the random baseline, and prints a per-class
    /// strategy ranking.
    func testAttributeStrategiesPerClass() async {
        await withDependencies {
            $0.context = .live
        } operation: {
            await runStrategyTest()
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

    private func runRandomSweep() async {
        @Dependency(\.attributeService)        var attributeService
        @Dependency(\.itemsRepository)         var itemsRepository
        @Dependency(\.snapshotBuilder)         var snapshotBuilder
        @Dependency(\.battleSimulationService) var simService

        var rows: [SweepRow] = []
        let sweepStart = Date()
        for level in levels {
            for matchup in matchups {
                let configStart = Date()
                let results = await runRandomBattles(
                    count: battleCount,
                    level: level,
                    matchup: matchup,
                    attributeService: attributeService,
                    itemsRepository: itemsRepository,
                    builder: snapshotBuilder,
                    service: simService
                )
                let row = aggregate(level: level, matchup: matchup, results: results)
                rows.append(row)
                let elapsed = Date().timeIntervalSince(configStart)
                print(String(format: "  • L%d %@ done — %.1fs (%d battles, random attrs)",
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

    private func makeRandomSnapshot(
        style: FightStyle,
        level: Int,
        name: String,
        attributeService: any AttributeService,
        itemsRepository: any ItemsRepository,
        builder: any CombatantSnapshotBuilder
    ) -> CombatantSnapshot {
        let fightStyleAttrs = attributeService.getAllFightStyleAttributes(for: style, at: Int16(level))
        // includeRandomAttributes = on → ~4 points × level distributed across
        // agi/str/pow/int/end via the live `attributeRandomizer`. Each call
        // returns a fresh roll, so per-battle invocation gives 30 000 distinct
        // random profiles per matchup.
        let randomLevelAttrs = attributeService.getAllRandomLevelAttributes(for: Int16(level))
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
                for i in 0..<battlesInBatch {
                    // Per-battle seeded generator: distinct lock per battle
                    // (no cross-battle contention) + reproducible by index.
                    let gen = WithRandomNumberGenerator(
                        SeededRandomNumberGenerator(seed: UInt64(startIndex + i))
                    )
                    group.addTask { await service.runSingleBattle(battle, using: gen) }
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

    /// Random-attributes variant: re-rolls fresh random-level attributes (and
    /// rebuilds snapshots) per battle so each draw is sampled from a distinct
    /// stat profile. Significantly more snapshot work but still inexpensive
    /// compared to running the battle itself.
    private func runRandomBattles(
        count: Int,
        level: Int,
        matchup: Matchup,
        attributeService: any AttributeService,
        itemsRepository: any ItemsRepository,
        builder: any CombatantSnapshotBuilder,
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
                for i in 0..<battlesInBatch {
                    let h1 = makeRandomSnapshot(
                        style: matchup.h1, level: level, name: "H1",
                        attributeService: attributeService,
                        itemsRepository: itemsRepository,
                        builder: builder
                    )
                    let h2 = makeRandomSnapshot(
                        style: matchup.h2, level: level, name: "H2",
                        attributeService: attributeService,
                        itemsRepository: itemsRepository,
                        builder: builder
                    )
                    let battle = Battle(leftTeam: [h1], rightTeam: [h2])
                    let gen = WithRandomNumberGenerator(
                        SeededRandomNumberGenerator(seed: UInt64(startIndex + i))
                    )
                    group.addTask { await service.runSingleBattle(battle, using: gen) }
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

    // MARK: - Attribute-value duel matrix

    private func runAttributeMatrix() async {
        @Dependency(\.itemsRepository)         var itemsRepository
        @Dependency(\.snapshotBuilder)         var snapshotBuilder
        @Dependency(\.battleSimulationService) var simService

        // Equal budget into each champion so the matrix reads as "what is N
        // points of stat X (or X+Y) worth in a fight". 48 ≈ a single L12
        // stat maxed out (dodge's agi is 4×12). HP fixed at the L12 baseline
        // (80 + 5×12) so HP isn't a hidden variable. Combos split 24+24.
        let budget: Int16 = 48
        let half = budget / 2
        let fifth = budget / 5
        let hp: Int16 = 140
        let level = 12
        let matrixBattles = 10_000

        let champions: [(name: String, attrs: HeroAttributes)] = [
            ("STR",     champ(hp: hp, str: budget)),
            ("AGI",     champ(hp: hp, agi: budget)),
            ("POW",     champ(hp: hp, pow: budget)),
            ("INT",     champ(hp: hp, int: budget)),
            ("END",     champ(hp: hp, end: budget)),
            ("BAL",     champ(hp: hp, str: fifth, agi: fifth, pow: fifth, int: fifth, end: fifth)),
            ("STR+END", champ(hp: hp, str: half, end: half)),
            ("POW+END", champ(hp: hp, pow: half, end: half)),
            ("AGI+INT", champ(hp: hp, agi: half, int: half)),
            ("POW+AGI", champ(hp: hp, agi: half, pow: half)),
        ]

        let equipped = HeroConfigurationState(level: level).makeEquipped(itemsRepository: itemsRepository)
        var snapshots: [(name: String, snap: CombatantSnapshot)] = []
        for champion in champions {
            let snap = snapshotBuilder.buildSnapshot(
                name: champion.name,
                imageName: "",
                level: level,
                fightStyleAttributes: champion.attrs,
                randomLevelAttributes: HeroAttributes(),
                equipped: equipped,
                globalBuffs: []
            )
            snapshots.append((champion.name, snap))
        }

        var rows: [MatrixRow] = []
        let start = Date()
        for i in 0..<snapshots.count {
            for j in (i + 1)..<snapshots.count {
                let a = snapshots[i]
                let b = snapshots[j]
                let battle = Battle(leftTeam: [a.snap], rightTeam: [b.snap])
                let results = await runBattles(count: matrixBattles, battle: battle, service: simService)
                var aWins = 0
                var bWins = 0
                var draws = 0
                var totalRounds = 0
                for r in results {
                    switch r.winner {
                    case .left:  aWins += 1
                    case .right: bWins += 1
                    case .draw:  draws += 1
                    }
                    totalRounds += r.totalRounds
                }
                let n = Double(max(results.count, 1))
                rows.append(MatrixRow(
                    a: a.name, b: b.name,
                    aWinPct: Double(aWins) / n * 100,
                    bWinPct: Double(bWins) / n * 100,
                    drawPct: Double(draws) / n * 100,
                    avgRounds: Double(totalRounds) / n
                ))
                print(String(format: "  • %@ vs %@ done (%d battles)", a.name, b.name, results.count))
            }
        }
        printAttributeMatrix(
            champions: champions.map { $0.name },
            rows: rows,
            budget: budget,
            elapsed: Date().timeIntervalSince(start)
        )
    }

    private func champ(
        hp: Int16,
        str: Int16 = 0,
        agi: Int16 = 0,
        pow: Int16 = 0,
        int: Int16 = 0,
        end: Int16 = 0
    ) -> HeroAttributes {
        HeroAttributes(
            hitPoints: Attribute(hp),
            manaPoints: 20,
            agility: Attribute(agi),
            strength: Attribute(str),
            power: Attribute(pow),
            instinct: Attribute(int),
            endurance: Attribute(end)
        )
    }

    private func printAttributeMatrix(
        champions: [String],
        rows: [MatrixRow],
        budget: Int16,
        elapsed: TimeInterval
    ) {
        let line = String(repeating: "=", count: 90)
        print()
        print(line)
        print(" Attribute-Value Duel Matrix — budget \(budget)/champion, HP 140, L12, Recruit's Spear")
        print(String(format: " %d pairs, wall clock %.1fs", rows.count, elapsed))
        print(line)
        print()
        // Per-pair detail. "net" = A win% − B win% (draws split shown separately).
        print(padRight("Matchup", 22)
              + padRight("A win%", 9)
              + padRight("B win%", 9)
              + padRight("draw%", 9)
              + padRight("net(A−B)", 10)
              + "avgRnd")
        print(String(repeating: "-", count: 90))
        for row in rows {
            let net = row.aWinPct - row.bWinPct
            print(padRight("\(row.a) vs \(row.b)", 22)
                  + padRight(String(format: "%5.1f", row.aWinPct), 9)
                  + padRight(String(format: "%5.1f", row.bWinPct), 9)
                  + padRight(String(format: "%5.1f", row.drawPct), 9)
                  + padRight(String(format: "%+5.1f", net), 10)
                  + String(format: "%.1f", row.avgRounds))
        }

        // Power ranking: each champion's mean draw-split win rate across all
        // its matches. High = strong stat, ~50 = balanced, low = weak/dead.
        var scoreSum: [String: Double] = [:]
        var matchCount: [String: Int] = [:]
        for row in rows {
            scoreSum[row.a, default: 0] += row.aWinPct + row.drawPct / 2
            scoreSum[row.b, default: 0] += row.bWinPct + row.drawPct / 2
            matchCount[row.a, default: 0] += 1
            matchCount[row.b, default: 0] += 1
        }
        print()
        print(" Power ranking (mean draw-split win% across all opponents):")
        print(String(repeating: "-", count: 90))
        let ranking = champions
            .map { (name: $0, score: scoreSum[$0, default: 0] / Double(max(matchCount[$0, default: 1], 1))) }
            .sorted { $0.score > $1.score }
        for (rank, entry) in ranking.enumerated() {
            print(String(format: "  %2d. %@  %5.1f%%", rank + 1, padRight(entry.name, 10), entry.score))
        }
        print(line)
    }

    // MARK: - Strategy choice test

    /// One bonus-pool allocation strategy: 4 points per level distributed
    /// across the 5 combat stats. Weights must sum to 4 — the strategy is
    /// applied multiplicatively by level (e.g., `str: 4` → +48 strength at L12).
    private struct AttrStrategy {
        let name: String
        let agi: Int16
        let str: Int16
        let pow: Int16
        let int: Int16
        let end: Int16
        /// Treat as `random` rolls instead of a fixed split. Used for the
        /// baseline + the opponent in every match.
        let isRandom: Bool
    }

    private func runStrategyTest() async {
        @Dependency(\.attributeService)        var attributeService
        @Dependency(\.itemsRepository)         var itemsRepository
        @Dependency(\.snapshotBuilder)         var snapshotBuilder
        @Dependency(\.battleSimulationService) var simService

        let level = 12
        let battlesPerCell = 5_000

        // Strategies that any class can adopt. "core" is class-specific and
        // resolved later.
        let strategies: [AttrStrategy] = [
            AttrStrategy(name: "random",   agi: 0, str: 0, pow: 0, int: 0, end: 0, isRandom: true),
            AttrStrategy(name: "all-STR",  agi: 0, str: 4, pow: 0, int: 0, end: 0, isRandom: false),
            AttrStrategy(name: "all-AGI",  agi: 4, str: 0, pow: 0, int: 0, end: 0, isRandom: false),
            AttrStrategy(name: "all-POW",  agi: 0, str: 0, pow: 4, int: 0, end: 0, isRandom: false),
            AttrStrategy(name: "all-INT",  agi: 0, str: 0, pow: 0, int: 4, end: 0, isRandom: false),
            AttrStrategy(name: "all-END",  agi: 0, str: 0, pow: 0, int: 0, end: 4, isRandom: false),
            AttrStrategy(name: "STR+END",  agi: 0, str: 2, pow: 0, int: 0, end: 2, isRandom: false),
        ]

        let allStyles: [FightStyle] = [.def, .crit, .dodge]
        let randomBaseline = strategies[0]

        // Output: per fight style, table of strategy -> winrate vs each opponent class (with random baseline).
        var allRows: [StrategyRow] = []
        let start = Date()
        for style in allStyles {
            for strategy in strategies {
                for opponent in allStyles where opponent != style {
                    let results = await runStrategyBattles(
                        count: battlesPerCell,
                        selfStyle: style, selfStrategy: strategy,
                        oppStyle: opponent, oppStrategy: randomBaseline,
                        level: level,
                        attributeService: attributeService,
                        itemsRepository: itemsRepository,
                        builder: snapshotBuilder,
                        service: simService
                    )
                    var sWins = 0, oWins = 0, draws = 0
                    for r in results {
                        switch r.winner {
                        case .left:  sWins += 1
                        case .right: oWins += 1
                        case .draw:  draws  += 1
                        }
                    }
                    let n = Double(max(results.count, 1))
                    allRows.append(StrategyRow(
                        style: style, strategy: strategy.name, opponent: opponent,
                        selfWinPct: Double(sWins) / n * 100,
                        opponentWinPct: Double(oWins) / n * 100,
                        drawPct: Double(draws) / n * 100
                    ))
                    print(String(format: "  • %@/%@ vs %@-random done (%d battles)",
                                 styleName(style), strategy.name, styleName(opponent), results.count))
                }
            }
        }
        printStrategyReport(rows: allRows, elapsed: Date().timeIntervalSince(start), level: level)
    }

    /// Each battle re-rolls fresh random attrs for whichever side is marked
    /// `isRandom = true`. Fixed-strategy sides reuse the same snapshot.
    private func runStrategyBattles(
        count: Int,
        selfStyle: FightStyle, selfStrategy: AttrStrategy,
        oppStyle: FightStyle, oppStrategy: AttrStrategy,
        level: Int,
        attributeService: any AttributeService,
        itemsRepository: any ItemsRepository,
        builder: any CombatantSnapshotBuilder,
        service: any BattleSimulationService
    ) async -> [BattleResult] {
        let equipped = HeroConfigurationState(level: level).makeEquipped(itemsRepository: itemsRepository)
        // Pre-build snapshots for fixed strategies.
        let selfFixedSnap = selfStrategy.isRandom ? nil : makeStrategySnapshot(
            style: selfStyle, strategy: selfStrategy, level: level,
            attributeService: attributeService, equipped: equipped, builder: builder, name: "S"
        )
        let oppFixedSnap = oppStrategy.isRandom ? nil : makeStrategySnapshot(
            style: oppStyle, strategy: oppStrategy, level: level,
            attributeService: attributeService, equipped: equipped, builder: builder, name: "O"
        )

        var allResults: [BattleResult] = []
        allResults.reserveCapacity(count)
        let batches = (count + batchSize - 1) / batchSize
        for batchIdx in 0..<batches {
            let startIdx = batchIdx * batchSize
            let endIdx = min(startIdx + batchSize, count)
            let n = endIdx - startIdx
            let batchResults = await withTaskGroup(of: BattleResult.self) { group in
                for i in 0..<n {
                    let s = selfFixedSnap ?? makeRandomSnapshot(
                        style: selfStyle, level: level, name: "S",
                        attributeService: attributeService,
                        itemsRepository: itemsRepository, builder: builder
                    )
                    let o = oppFixedSnap ?? makeRandomSnapshot(
                        style: oppStyle, level: level, name: "O",
                        attributeService: attributeService,
                        itemsRepository: itemsRepository, builder: builder
                    )
                    let battle = Battle(leftTeam: [s], rightTeam: [o])
                    let gen = WithRandomNumberGenerator(
                        SeededRandomNumberGenerator(seed: UInt64(startIdx + i))
                    )
                    group.addTask { await service.runSingleBattle(battle, using: gen) }
                }
                var results: [BattleResult] = []
                results.reserveCapacity(n)
                for await r in group { results.append(r) }
                return results
            }
            allResults.append(contentsOf: batchResults)
        }
        return allResults
    }

    private func makeStrategySnapshot(
        style: FightStyle, strategy: AttrStrategy, level: Int,
        attributeService: any AttributeService,
        equipped: EquippedItems,
        builder: any CombatantSnapshotBuilder,
        name: String
    ) -> CombatantSnapshot {
        let fightStyleAttrs = attributeService.getAllFightStyleAttributes(for: style, at: Int16(level))
        let lv = Int16(level)
        let bonusAttrs = HeroAttributes(
            hitPoints: Attribute(0), manaPoints: Attribute(0),
            agility: Attribute(strategy.agi * lv),
            strength: Attribute(strategy.str * lv),
            power: Attribute(strategy.pow * lv),
            instinct: Attribute(strategy.int * lv),
            endurance: Attribute(strategy.end * lv)
        )
        return builder.buildSnapshot(
            name: name, imageName: "", level: level,
            fightStyleAttributes: fightStyleAttrs,
            randomLevelAttributes: bonusAttrs,
            equipped: equipped, globalBuffs: []
        )
    }

    private func printStrategyReport(rows: [StrategyRow], elapsed: TimeInterval, level: Int) {
        let line = String(repeating: "=", count: 90)
        print()
        print(line)
        print(" Attribute Strategy Choice — L\(level), 5 000 battles/cell")
        print(String(format: " %d cells, wall clock %.1fs", rows.count, elapsed))
        print(line)
        for style in [FightStyle.def, .crit, .dodge] {
            let styleRows = rows.filter { $0.style == style }
            print()
            print(" === \(styleName(style).uppercased()) — strategy vs random opponents ===")
            print(padRight("Strategy", 12)
                  + padRight("vs def", 10)
                  + padRight("vs crit", 10)
                  + padRight("vs dodge", 10)
                  + padRight("avg", 10)
                  + padRight("draw-split avg", 10))
            print(String(repeating: "-", count: 70))

            let strategies = Array(Set(styleRows.map { $0.strategy }))
            let ordered = ["random", "all-STR", "all-AGI", "all-POW", "all-INT", "all-END", "STR+END"]
            let sortedStrategies = ordered.filter { strategies.contains($0) }
            var summaryEntries: [(String, Double)] = []
            for strategy in sortedStrategies {
                var winVsDef = "—", winVsCrit = "—", winVsDodge = "—"
                var winSum = 0.0, drawSplitSum = 0.0, opponentCount = 0
                for opp in [FightStyle.def, .crit, .dodge] where opp != style {
                    if let row = styleRows.first(where: { $0.strategy == strategy && $0.opponent == opp }) {
                        let w = String(format: "%5.1f%%", row.selfWinPct)
                        winSum += row.selfWinPct
                        drawSplitSum += row.selfWinPct + row.drawPct / 2
                        opponentCount += 1
                        switch opp {
                        case .def:   winVsDef = w
                        case .crit:  winVsCrit = w
                        case .dodge: winVsDodge = w
                        }
                    }
                }
                let avgWin = opponentCount > 0 ? winSum / Double(opponentCount) : 0
                let drawSplitAvg = opponentCount > 0 ? drawSplitSum / Double(opponentCount) : 0
                summaryEntries.append((strategy, drawSplitAvg))
                print(padRight(strategy, 12)
                      + padRight(winVsDef, 10)
                      + padRight(winVsCrit, 10)
                      + padRight(winVsDodge, 10)
                      + padRight(String(format: "%5.1f%%", avgWin), 10)
                      + String(format: "%5.1f%%", drawSplitAvg))
            }
            print()
            print(" Best strategies for \(styleName(style)):")
            for (rank, entry) in summaryEntries.sorted(by: { $0.1 > $1.1 }).enumerated() {
                print(String(format: "   %d. %@  %5.1f%%", rank + 1, padRight(entry.0, 12), entry.1))
            }
        }
        print(line)
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

    private struct StrategyRow {
        let style: FightStyle
        let strategy: String
        let opponent: FightStyle
        let selfWinPct: Double
        let opponentWinPct: Double
        let drawPct: Double
    }

    private struct MatrixRow {
        let a: String
        let b: String
        let aWinPct: Double
        let bWinPct: Double
        let drawPct: Double
        let avgRounds: Double
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

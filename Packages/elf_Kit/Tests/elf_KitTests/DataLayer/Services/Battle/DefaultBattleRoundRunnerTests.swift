//
//  DefaultBattleRoundRunnerTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for DefaultBattleRoundRunner.
///
/// The runner is the single source of truth for "one round" mechanics.
/// These tests pin down the contract: hero pair uses provided selection,
/// non-hero pairs use bot AI, HP clamps at zero, outcome detection at
/// boundary conditions, pair-result order matches input.
final class DefaultBattleRoundRunnerTests: XCTestCase {

    // MARK: - Mocks

    /// Captures inputs and returns a configurable damage result.
    final class MockExecutor: CombatRoundExecutor, @unchecked Sendable {
        struct Capture: Sendable {
            let playerSnapshot: CombatantSnapshot
            let botSnapshot: CombatantSnapshot
            let playerAttackPoints: Set<BodyPart>
            let playerDefensePoints: Set<BodyPart>
            let botAttackPoints: Set<BodyPart>
            let botDefensePoints: Set<BodyPart>
        }

        nonisolated(unsafe) var captures: [Capture] = []
        nonisolated(unsafe) var damageToPlayer: Int = 0
        nonisolated(unsafe) var damageToBot: Int = 0

        func executeRound(
            playerSnapshot: CombatantSnapshot,
            botSnapshot: CombatantSnapshot,
            playerAttackPoints: Set<BodyPart>,
            playerDefensePoints: Set<BodyPart>,
            botAttackPoints: Set<BodyPart>,
            botDefensePoints: Set<BodyPart>
        ) -> CombatRoundResult {
            captures.append(Capture(
                playerSnapshot: playerSnapshot,
                botSnapshot: botSnapshot,
                playerAttackPoints: playerAttackPoints,
                playerDefensePoints: playerDefensePoints,
                botAttackPoints: botAttackPoints,
                botDefensePoints: botDefensePoints
            ))
            return CombatRoundResult(
                playerResults: [:],
                botResults: [:],
                playerDamageTaken: damageToPlayer,
                botDamageTaken: damageToBot
            )
        }
    }

    /// Returns fixed attack/defense sets so we can verify which pair received what.
    final class FixedBotAI: BotAIService, @unchecked Sendable {
        nonisolated(unsafe) var attackChoice: Set<BodyPart> = [.head]
        nonisolated(unsafe) var defenseChoice: Set<BodyPart> = [.body]

        func selectAttackPoints(count: Int) -> Set<BodyPart> { attackChoice }
        func selectDefensePoints(count: Int) -> Set<BodyPart> { defenseChoice }
    }

    // MARK: - Helpers

    private func makeCombatant(
        id: UUID = UUID(),
        name: String = "C",
        currentHP: Int = 100,
        maxHP: Int = 100,
        attackPoints: Int = 1,
        defensePoints: Int = 1
    ) -> CombatantSnapshot {
        CombatantSnapshot(
            id: id,
            sourceId: UUID(),
            name: name,
            imageName: "img",
            combatantType: .elf,
            level: 1,
            currentHP: currentHP,
            maxHP: maxHP,
            strength: 10,
            agility: 10,
            power: 10,
            intuition: 10,
            attackPoints: attackPoints,
            defensePoints: defensePoints,
            minimumAttack: 1,
            maximumAttack: 5,
            armorValues: [:]
        )
    }

    private func makeRound(
        leftIds: [UUID],
        rightIds: [UUID],
        roundNumber: Int = 1
    ) -> BattleRound {
        let pairs = zip(leftIds, rightIds).map { left, right in
            DuelPair(leftCombatantId: left, rightCombatantId: right)
        }
        return BattleRound(roundNumber: roundNumber, duelPairs: pairs)
    }

    // MARK: - Tests

    func testHeroPair_UsesProvidedSelection() async {
        let hero = makeCombatant(name: "Hero")
        let opponent = makeCombatant(name: "Opp")
        let round = makeRound(leftIds: [hero.id], rightIds: [opponent.id])
        let heroSelection = HeroSelection(
            combatantId: hero.id,
            attackPoints: [.legs],
            defensePoints: [.head, .body]
        )

        let executor = MockExecutor()
        let bot = FixedBotAI()

        let outcome = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = bot
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: [hero],
                rightTeam: [opponent],
                round: round,
                heroSelection: heroSelection
            )
        }

        XCTAssertEqual(executor.captures.count, 1)
        let capture = executor.captures[0]
        XCTAssertEqual(capture.playerAttackPoints, [.legs], "hero pair should forward heroSelection.attackPoints")
        XCTAssertEqual(capture.playerDefensePoints, [.head, .body], "hero pair should forward heroSelection.defensePoints")
        XCTAssertEqual(outcome.pairResults.count, 1)
        XCTAssertTrue(outcome.pairResults[0].isHeroPair)
    }

    func testNonHeroPair_UsesBotAI() async {
        let leftA = makeCombatant(name: "A")
        let leftB = makeCombatant(name: "B")
        let rightA = makeCombatant(name: "X")
        let rightB = makeCombatant(name: "Y")
        let round = makeRound(leftIds: [leftA.id, leftB.id], rightIds: [rightA.id, rightB.id])

        let executor = MockExecutor()
        let bot = FixedBotAI()
        bot.attackChoice = [.rightHand]
        bot.defenseChoice = [.leftHand]

        let outcome = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = bot
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: [leftA, leftB],
                rightTeam: [rightA, rightB],
                round: round,
                heroSelection: nil  // fully auto
            )
        }

        XCTAssertEqual(executor.captures.count, 2)
        for capture in executor.captures {
            XCTAssertEqual(capture.playerAttackPoints, [.rightHand], "every non-hero pair uses bot AI for left attack")
            XCTAssertEqual(capture.playerDefensePoints, [.leftHand], "every non-hero pair uses bot AI for left defense")
            XCTAssertEqual(capture.botAttackPoints, [.rightHand], "every right side uses bot AI for attack")
            XCTAssertEqual(capture.botDefensePoints, [.leftHand], "every right side uses bot AI for defense")
        }
        XCTAssertFalse(outcome.pairResults.contains(where: { $0.isHeroPair }))
    }

    func testHPClampsAtZero() async {
        let left = makeCombatant(name: "L", currentHP: 30)
        let right = makeCombatant(name: "R", currentHP: 30)
        let round = makeRound(leftIds: [left.id], rightIds: [right.id])

        let executor = MockExecutor()
        executor.damageToPlayer = 100  // overkill
        executor.damageToBot = 100     // overkill

        let outcome = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = FixedBotAI()
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: [left],
                rightTeam: [right],
                round: round,
                heroSelection: nil
            )
        }

        XCTAssertEqual(outcome.updatedLeftTeam[0].currentHP, 0, "HP must clamp at 0, not go negative")
        XCTAssertEqual(outcome.updatedRightTeam[0].currentHP, 0)
        XCTAssertEqual(outcome.pairResults[0].leftNewHP, 0)
        XCTAssertEqual(outcome.pairResults[0].rightNewHP, 0)
        XCTAssertEqual(outcome.battleOutcome, .draw, "both sides at 0 HP → draw")
    }

    func testBattleOutcome_Victory() async {
        let left = makeCombatant(name: "L", currentHP: 100)
        let right = makeCombatant(name: "R", currentHP: 30)
        let round = makeRound(leftIds: [left.id], rightIds: [right.id])

        let executor = MockExecutor()
        executor.damageToPlayer = 0
        executor.damageToBot = 100  // kills right

        let outcome = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = FixedBotAI()
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: [left], rightTeam: [right],
                round: round, heroSelection: nil
            )
        }

        XCTAssertEqual(outcome.battleOutcome, .victory)
    }

    func testBattleOutcome_Defeat() async {
        let left = makeCombatant(name: "L", currentHP: 30)
        let right = makeCombatant(name: "R", currentHP: 100)
        let round = makeRound(leftIds: [left.id], rightIds: [right.id])

        let executor = MockExecutor()
        executor.damageToPlayer = 100  // kills left
        executor.damageToBot = 0

        let outcome = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = FixedBotAI()
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: [left], rightTeam: [right],
                round: round, heroSelection: nil
            )
        }

        XCTAssertEqual(outcome.battleOutcome, .defeat)
    }

    func testBattleOutcome_NilWhenBothSurvive() async {
        let left = makeCombatant(name: "L", currentHP: 100)
        let right = makeCombatant(name: "R", currentHP: 100)
        let round = makeRound(leftIds: [left.id], rightIds: [right.id])

        let executor = MockExecutor()
        executor.damageToPlayer = 10
        executor.damageToBot = 10

        let outcome = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = FixedBotAI()
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: [left], rightTeam: [right],
                round: round, heroSelection: nil
            )
        }

        XCTAssertNil(outcome.battleOutcome, "battle continues while both sides have alive combatants")
        XCTAssertEqual(outcome.updatedLeftTeam[0].currentHP, 90)
        XCTAssertEqual(outcome.updatedRightTeam[0].currentHP, 90)
    }

    func testPairResults_PreserveDuelPairOrder() async {
        let left = (0..<5).map { _ in makeCombatant() }
        let right = (0..<5).map { _ in makeCombatant() }
        // Build round with pairs in non-trivial order: 0-4, 1-3, 2-2, 3-1, 4-0
        let pairs = (0..<5).map { i in
            DuelPair(leftCombatantId: left[i].id, rightCombatantId: right[4 - i].id)
        }
        let round = BattleRound(roundNumber: 1, duelPairs: pairs)

        let executor = MockExecutor()

        let outcome = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = FixedBotAI()
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: left, rightTeam: right,
                round: round, heroSelection: nil
            )
        }

        XCTAssertEqual(outcome.pairResults.count, 5)
        for (i, pairResult) in outcome.pairResults.enumerated() {
            XCTAssertEqual(pairResult.leftCombatantId, left[i].id, "pair index \(i) left id")
            XCTAssertEqual(pairResult.rightCombatantId, right[4 - i].id, "pair index \(i) right id")
        }
        XCTAssertEqual(outcome.updatedLeftTeam.map(\.id), left.map(\.id), "team order preserved")
        XCTAssertEqual(outcome.updatedRightTeam.map(\.id), right.map(\.id))
    }

    func testHeroIsWaiting_HeroSelectionIgnored() async {
        // Hero is alive but NOT in any pair this round (e.g. landed in
        // waitingLeftIds). All pairs should fall through to bot AI.
        let hero = makeCombatant(name: "Hero")
        let pairedLeft = makeCombatant(name: "Friend")
        let opponent = makeCombatant(name: "Opp")
        let round = makeRound(leftIds: [pairedLeft.id], rightIds: [opponent.id])
        let heroSelection = HeroSelection(
            combatantId: hero.id,
            attackPoints: [.legs],
            defensePoints: [.head]
        )

        let executor = MockExecutor()
        let bot = FixedBotAI()
        bot.attackChoice = [.body]
        bot.defenseChoice = [.rightHand]

        let outcome = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = bot
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: [hero, pairedLeft],
                rightTeam: [opponent],
                round: round,
                heroSelection: heroSelection
            )
        }

        XCTAssertEqual(executor.captures.count, 1)
        let capture = executor.captures[0]
        XCTAssertEqual(capture.playerAttackPoints, [.body], "hero not paired → bot AI used for left side")
        XCTAssertEqual(capture.playerDefensePoints, [.rightHand])
        XCTAssertFalse(outcome.pairResults[0].isHeroPair)
    }

    func testNilHeroSelection_AllPairsUseBotAI() async {
        let leftA = makeCombatant(name: "A")
        let rightA = makeCombatant(name: "X")
        let round = makeRound(leftIds: [leftA.id], rightIds: [rightA.id])

        let executor = MockExecutor()
        let bot = FixedBotAI()
        bot.attackChoice = [.head]
        bot.defenseChoice = [.legs]

        let outcome = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = bot
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: [leftA], rightTeam: [rightA],
                round: round, heroSelection: nil
            )
        }

        XCTAssertEqual(executor.captures[0].playerAttackPoints, [.head])
        XCTAssertEqual(executor.captures[0].playerDefensePoints, [.legs])
        XCTAssertFalse(outcome.pairResults[0].isHeroPair)
    }

    func testPairResult_CarriesPreRoundSnapshots() async {
        // Regression guard: pair.leftSnapshot/rightSnapshot must capture HP
        // BEFORE damage is applied, so the consumer can log "round start"
        // state correctly.
        let left = makeCombatant(name: "L", currentHP: 100)
        let right = makeCombatant(name: "R", currentHP: 100)
        let round = makeRound(leftIds: [left.id], rightIds: [right.id])

        let executor = MockExecutor()
        executor.damageToPlayer = 30
        executor.damageToBot = 30

        let outcome = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = FixedBotAI()
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: [left], rightTeam: [right],
                round: round, heroSelection: nil
            )
        }

        let pair = outcome.pairResults[0]
        XCTAssertEqual(pair.leftSnapshot.currentHP, 100, "leftSnapshot must reflect pre-round HP")
        XCTAssertEqual(pair.rightSnapshot.currentHP, 100, "rightSnapshot must reflect pre-round HP")
        XCTAssertEqual(pair.leftOldHP, 100)
        XCTAssertEqual(pair.leftNewHP, 70)
        XCTAssertEqual(outcome.updatedLeftTeam[0].currentHP, 70, "updatedTeam reflects post-round HP")
    }

    // MARK: - BattleResult.Winner mapping

    func testWinnerMapping_Victory_IsLeft() {
        XCTAssertEqual(BattleResult.Winner(from: .victory), .left)
    }

    func testWinnerMapping_Defeat_IsRight() {
        XCTAssertEqual(BattleResult.Winner(from: .defeat), .right)
    }

    func testWinnerMapping_Draw_IsDraw() {
        XCTAssertEqual(BattleResult.Winner(from: .draw), .draw)
    }

    func testEmptyRound_NoPairs() async {
        let left = makeCombatant()
        let right = makeCombatant()
        let round = BattleRound(roundNumber: 1, duelPairs: [])

        let outcome = await withDependencies {
            $0.combatRoundExecutor = MockExecutor()
            $0.botAI = FixedBotAI()
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: [left], rightTeam: [right],
                round: round, heroSelection: nil
            )
        }

        XCTAssertEqual(outcome.pairResults.count, 0)
        XCTAssertEqual(outcome.updatedLeftTeam.map(\.id), [left.id], "teams unchanged when no pairs")
        XCTAssertEqual(outcome.updatedRightTeam.map(\.id), [right.id])
        XCTAssertNil(outcome.battleOutcome, "no pairs → no damage → both alive → continues")
    }
}

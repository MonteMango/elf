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

        private let lock = NSLock()
        private var _captures: [Capture] = []
        private var _damageToPlayer: Int = 0
        private var _damageToBot: Int = 0
        private var _epSpentByPlayer: Int = 0
        private var _epSpentByBot: Int = 0

        var captures: [Capture] {
            lock.withLock { _captures }
        }

        var damageToPlayer: Int {
            get { lock.withLock { _damageToPlayer } }
            set { lock.withLock { _damageToPlayer = newValue } }
        }

        var damageToBot: Int {
            get { lock.withLock { _damageToBot } }
            set { lock.withLock { _damageToBot = newValue } }
        }

        var epSpentByPlayer: Int {
            get { lock.withLock { _epSpentByPlayer } }
            set { lock.withLock { _epSpentByPlayer = newValue } }
        }

        var epSpentByBot: Int {
            get { lock.withLock { _epSpentByBot } }
            set { lock.withLock { _epSpentByBot = newValue } }
        }

        func executeRound(
            playerSnapshot: CombatantSnapshot,
            botSnapshot: CombatantSnapshot,
            playerAttackPoints: Set<BodyPart>,
            playerDefensePoints: Set<BodyPart>,
            botAttackPoints: Set<BodyPart>,
            botDefensePoints: Set<BodyPart>,
            using generator: WithRandomNumberGenerator
        ) -> CombatRoundResult {
            lock.withLock {
                _captures.append(Capture(
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
                    playerDamageTaken: _damageToPlayer,
                    botDamageTaken: _damageToBot,
                    playerEPSpent: _epSpentByPlayer,
                    botEPSpent: _epSpentByBot
                )
            }
        }
    }

    /// Returns fixed attack/defense sets so we can verify which pair received what.
    final class FixedBotAI: BotAIService, @unchecked Sendable {
        private let lock = NSLock()
        private var _attackChoice: Set<BodyPart> = [.head]
        private var _defenseChoice: Set<BodyPart> = [.body]

        var attackChoice: Set<BodyPart> {
            get { lock.withLock { _attackChoice } }
            set { lock.withLock { _attackChoice = newValue } }
        }

        var defenseChoice: Set<BodyPart> {
            get { lock.withLock { _defenseChoice } }
            set { lock.withLock { _defenseChoice = newValue } }
        }

        func selectAttackPoints(count: Int, using generator: WithRandomNumberGenerator) -> Set<BodyPart> {
            lock.withLock { _attackChoice }
        }

        func selectDefensePoints(count: Int, using generator: WithRandomNumberGenerator) -> Set<BodyPart> {
            lock.withLock { _defenseChoice }
        }
    }

    // MARK: - Helpers

    private func makeCombatant(
        id: UUID = UUID(),
        name: String = "C",
        currentHP: Int = 100,
        maxHP: Int = 100,
        currentMP: Int = 0,
        currentEP: Int = GameMechanicsConstants.startingEP,
        maxEP: Int = GameMechanicsConstants.startingEP,
        attackPoints: Int = 1,
        defensePoints: Int = 1
    ) -> CombatantSnapshot {
        let attacks = Array(
            repeating: AttackProfile(minimumAttack: 1, maximumAttack: 5, epBlockCost: 0),
            count: max(1, attackPoints)
        )
        return CombatantSnapshot(
            id: id,
            sourceId: UUID(),
            name: name,
            imageName: "img",
            combatantType: .elf,
            level: 1,
            currentHP: currentHP,
            currentMP: currentMP,
            currentEP: currentEP,
            maxEP: maxEP,
            baseHeroAttributes: HeroAttributes(
                hitPoints: Attribute(Int16(clamping: maxHP)),
                manaPoints: 0,
                agility: 10,
                strength: 10,
                power: 10,
                instinct: 10,
                endurance: 0
            ),
            attacks: attacks,
            defensePoints: defensePoints,
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

    // MARK: - Setup

    /// `runRound`'s convenience overload resolves `\.withRandomNumberGenerator`;
    /// seed it so the strict test value doesn't report (MockExecutor ignores
    /// the generator, but the overload still resolves it).
    override func invokeTest() {
        withDependencies {
            $0.withRandomNumberGenerator = WithRandomNumberGenerator(
                SeededRandomNumberGenerator(seed: 0xE1F)
            )
        } operation: {
            super.invokeTest()
        }
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

    // MARK: - EP mutation

    func testEPDecrementsAfterRound() async {
        let pool = GameMechanicsConstants.startingEP
        let left = makeCombatant(name: "L", currentEP: pool)
        let right = makeCombatant(name: "R", currentEP: pool)
        let round = makeRound(leftIds: [left.id], rightIds: [right.id])

        let executor = MockExecutor()
        executor.epSpentByPlayer = 200  // left side spent 200 EP
        executor.epSpentByBot = 400     // right side spent 400 EP

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

        XCTAssertEqual(outcome.updatedLeftTeam[0].currentEP, pool - 200)
        XCTAssertEqual(outcome.updatedRightTeam[0].currentEP, pool - 400)
        XCTAssertEqual(outcome.pairResults[0].result.playerEPSpent, 200)
        XCTAssertEqual(outcome.pairResults[0].result.botEPSpent, 400)
    }

    func testEPClampsAtZero() async {
        let left = makeCombatant(currentEP: 100)
        let right = makeCombatant(currentEP: 100)
        let round = makeRound(leftIds: [left.id], rightIds: [right.id])

        let executor = MockExecutor()
        executor.epSpentByPlayer = 500  // overspend
        executor.epSpentByBot = 500

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

        XCTAssertEqual(outcome.updatedLeftTeam[0].currentEP, 0, "EP must clamp at 0, not negative")
        XCTAssertEqual(outcome.updatedRightTeam[0].currentEP, 0)
    }

    // MARK: - End-of-round Exhausted application

    /// Hand the runner's `BuffApplicationService` a catalog containing the
    /// real `ExhaustedBattle` UUID so `applyAsBattle` actually finds the buff.
    /// Without this override, `testValue` for `buffsRepository` is empty and
    /// `applyAsBattle` no-ops.
    private func exhaustedBattleBuffCatalog() -> Buff {
        Buff(
            id: BuffCatalogID.exhaustedBattle,
            title: "Exhausted",
            imageName: "",
            description: "",
            polarity: .negative,
            scope: .battle,
            durationDays: nil,
            stackingRule: .ignore,
            effects: []
        )
    }

    func testExhaustedApplied_WhenEPHitsZero() async {
        let left = makeCombatant(currentEP: 100)
        let right = makeCombatant(currentEP: 100)
        let round = makeRound(leftIds: [left.id], rightIds: [right.id])

        let executor = MockExecutor()
        executor.epSpentByPlayer = 200  // overspend → EP clamps to 0
        executor.epSpentByBot = 0       // right keeps EP

        let outcome = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = FixedBotAI()
            $0.buffsRepository = ElfBuffsRepository(
                buffsData: BuffsData(version: "1.0-test", buffs: [exhaustedBattleBuffCatalog()])
            )
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: [left], rightTeam: [right],
                round: round, heroSelection: nil
            )
        }

        XCTAssertTrue(
            outcome.updatedLeftTeam[0].battleBuffs.contains { $0.buffId == BuffCatalogID.exhaustedBattle },
            "Left ended round at 0 EP — Exhausted must be applied"
        )
        XCTAssertFalse(
            outcome.updatedRightTeam[0].battleBuffs.contains { $0.buffId == BuffCatalogID.exhaustedBattle },
            "Right still has EP — no Exhausted"
        )
    }

    func testExhaustedNotApplied_WhenEPRemains() async {
        let left = makeCombatant(currentEP: 1000)
        let right = makeCombatant(currentEP: 1000)
        let round = makeRound(leftIds: [left.id], rightIds: [right.id])

        let executor = MockExecutor()
        executor.epSpentByPlayer = 100
        executor.epSpentByBot = 100

        let outcome = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = FixedBotAI()
            $0.buffsRepository = ElfBuffsRepository(
                buffsData: BuffsData(version: "1.0-test", buffs: [exhaustedBattleBuffCatalog()])
            )
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: [left], rightTeam: [right],
                round: round, heroSelection: nil
            )
        }

        XCTAssertTrue(outcome.updatedLeftTeam[0].battleBuffs.isEmpty)
        XCTAssertTrue(outcome.updatedRightTeam[0].battleBuffs.isEmpty)
    }

    func testExhaustedNotDuplicated_OnSecondZeroEPRound() async {
        // First round drains the defender to 0 EP and adds Exhausted; a second
        // round (also at 0 EP) must NOT add a second copy — `ExhaustedBattle`
        // has stackingRule `.ignore`.
        let left = makeCombatant(currentEP: 100)
        let right = makeCombatant(currentEP: 1000)
        let round1 = makeRound(leftIds: [left.id], rightIds: [right.id])

        let executor = MockExecutor()
        executor.epSpentByPlayer = 200  // EP clamps to 0
        executor.epSpentByBot = 0

        let (firstOutcome, secondOutcome) = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = FixedBotAI()
            $0.buffsRepository = ElfBuffsRepository(
                buffsData: BuffsData(version: "1.0-test", buffs: [exhaustedBattleBuffCatalog()])
            )
        } operation: {
            let runner = DefaultBattleRoundRunner()
            let r1 = await runner.runRound(
                leftTeam: [left], rightTeam: [right],
                round: round1, heroSelection: nil
            )
            executor.epSpentByPlayer = 0   // no EP to spend on second round
            let updatedLeft = r1.updatedLeftTeam
            let updatedRight = r1.updatedRightTeam
            let round2 = makeRound(leftIds: [updatedLeft[0].id], rightIds: [updatedRight[0].id], roundNumber: 2)
            let r2 = await runner.runRound(
                leftTeam: updatedLeft, rightTeam: updatedRight,
                round: round2, heroSelection: nil
            )
            return (r1, r2)
        }

        let exhaustedFirst = firstOutcome.updatedLeftTeam[0].battleBuffs.filter { $0.buffId == BuffCatalogID.exhaustedBattle }
        let exhaustedSecond = secondOutcome.updatedLeftTeam[0].battleBuffs.filter { $0.buffId == BuffCatalogID.exhaustedBattle }
        XCTAssertEqual(exhaustedFirst.count, 1, "First round applies one Exhausted")
        XCTAssertEqual(exhaustedSecond.count, 1, "Second round at EP=0 must not duplicate Exhausted")
    }

    func testExhaustedNotApplied_WhenDefenderIsDead() async {
        // Dead combatants don't get further debuffs — Exhausted is purely a
        // gameplay hint for the next round, which dead combatants don't have.
        let left = makeCombatant(currentHP: 10, currentEP: 100)
        let right = makeCombatant(currentEP: 1000)
        let round = makeRound(leftIds: [left.id], rightIds: [right.id])

        let executor = MockExecutor()
        executor.damageToPlayer = 100      // kills left
        executor.epSpentByPlayer = 200     // left ends at 0 EP too

        let outcome = await withDependencies {
            $0.combatRoundExecutor = executor
            $0.botAI = FixedBotAI()
            $0.buffsRepository = ElfBuffsRepository(
                buffsData: BuffsData(version: "1.0-test", buffs: [exhaustedBattleBuffCatalog()])
            )
        } operation: {
            let runner = DefaultBattleRoundRunner()
            return await runner.runRound(
                leftTeam: [left], rightTeam: [right],
                round: round, heroSelection: nil
            )
        }

        XCTAssertEqual(outcome.updatedLeftTeam[0].currentHP, 0)
        XCTAssertEqual(outcome.updatedLeftTeam[0].currentEP, 0)
        XCTAssertFalse(
            outcome.updatedLeftTeam[0].battleBuffs.contains { $0.buffId == BuffCatalogID.exhaustedBattle },
            "Dead combatant must not receive Exhausted"
        )
    }
}

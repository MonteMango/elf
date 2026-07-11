//
//  DuelPairingMutatorTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests the `DuelPairingMutator` extracted from `BattleFightViewModel`'s
/// `generateNewRoundPairings` (T16): delegating pairing generation to
/// `DuelPairingService`, deriving the bot snapshot to display for the hero's
/// duel pair (falling back to the previous snapshot when the hero has no
/// paired opponent this round), and forwarding the round-state debug log.
/// Exercised directly against the injected type (via
/// `@Dependency(\.duelPairingMutator)`), independent of `BattleFightViewModel`
/// — `BattleFightViewModelTests` must keep passing unchanged.
final class DuelPairingMutatorTests: XCTestCase {

    // MARK: - Mocks

    /// Returns a fixed `BattleRound` regardless of input, so the mutator's
    /// bot-snapshot derivation and debug-log forwarding can be pinned down
    /// without exercising real shuffling.
    final class StubDuelPairingService: DuelPairingService, @unchecked Sendable {
        var battleRound: BattleRound

        init(battleRound: BattleRound) {
            self.battleRound = battleRound
        }

        func createRandomPairs(
            leftTeam: [CombatantSnapshot],
            rightTeam: [CombatantSnapshot],
            roundNumber: Int
        ) -> BattleRound {
            battleRound
        }
    }

    /// Captures the last `logRoundState` call so tests can assert the mutator
    /// forwards the round-state debug log formerly inlined on the ViewModel.
    final class SpyDebugBattleLogger: DebugBattleLogger, @unchecked Sendable {
        struct RoundStateCall {
            let roundNumber: Int
            let leftTeam: [CombatantSnapshot]
            let rightTeam: [CombatantSnapshot]
            let playerCombatantId: CombatantID?
            let battleRound: BattleRound?
        }

        private(set) var roundStateCalls: [RoundStateCall] = []

        func logRoundStart(
            roundNumber: Int,
            playerSnapshot: CombatantSnapshot,
            botSnapshot: CombatantSnapshot,
            playerAttack: [BodyPart],
            playerDefense: [BodyPart],
            botAttack: [BodyPart],
            botDefense: [BodyPart]
        ) {}

        func logDodgeCalculation(
            defender: String,
            result: DodgeCalculationResult,
            agility: Int16,
            instinct: Int16
        ) {}

        func logCritCalculation(
            attacker: String,
            result: CritCalculationResult,
            power: Int16,
            instinct: Int16
        ) {}

        func logBodyPartCalculation(
            attacker: String,
            defender: String,
            bodyPart: BodyPart,
            isAttacked: Bool,
            isDefended: Bool,
            baseDamage: Int?,
            armor: Int?,
            finalDamage: Int?,
            finalStatus: PointStatus
        ) {}

        func logRoundEnd(
            roundNumber: Int,
            playerOldHP: Int,
            playerNewHP: Int,
            botOldHP: Int,
            botNewHP: Int,
            playerResults: [BodyPart: PointStatus],
            botResults: [BodyPart: PointStatus]
        ) {}

        func logRoundState(
            roundNumber: Int,
            leftTeam: [CombatantSnapshot],
            rightTeam: [CombatantSnapshot],
            playerCombatantId: CombatantID?,
            battleRound: BattleRound?
        ) {
            roundStateCalls.append(
                RoundStateCall(
                    roundNumber: roundNumber,
                    leftTeam: leftTeam,
                    rightTeam: rightTeam,
                    playerCombatantId: playerCombatantId,
                    battleRound: battleRound
                )
            )
        }
    }

    // MARK: - Fixtures

    private func makeCombatant(id: CombatantID = CombatantID(), currentHP: Int = 100) -> CombatantSnapshot {
        CombatantSnapshot(
            id: id,
            source: .synthetic,
            name: "C",
            imageName: "img",
            combatantType: .elf,
            level: 1,
            currentHP: currentHP,
            currentMP: 0,
            currentEP: GameMechanicsConstants.startingEP,
            maxEP: GameMechanicsConstants.startingEP,
            baseHeroAttributes: HeroAttributes(
                hitPoints: Attribute(100),
                manaPoints: 0,
                agility: 10,
                strength: 10,
                power: 10,
                instinct: 10,
                endurance: 0
            ),
            attacks: [AttackProfile(minimumAttack: 1, maximumAttack: 5, epBlockCost: 0)],
            defensePoints: 1,
            armorValues: [:]
        )
    }

    private func generatePairings(
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        roundNumber: Int,
        playerCombatantId: CombatantID?,
        previousDisplayedBotSnapshot: CombatantSnapshot?,
        stubBattleRound: BattleRound,
        spyLogger: SpyDebugBattleLogger
    ) -> DuelPairingResult {
        withDependencies {
            $0.duelPairingService = StubDuelPairingService(battleRound: stubBattleRound)
            $0.debugBattleLogger = spyLogger
        } operation: {
            @Dependency(\.duelPairingMutator) var mutator
            return mutator.generateNewRoundPairings(
                leftTeam: leftTeam,
                rightTeam: rightTeam,
                roundNumber: roundNumber,
                playerCombatantId: playerCombatantId,
                previousDisplayedBotSnapshot: previousDisplayedBotSnapshot
            )
        }
    }

    // MARK: - Tests

    func testGenerateNewRoundPairings_DelegatesToDuelPairingService_ReturnsItsBattleRound() {
        let hero = makeCombatant()
        let bot = makeCombatant()
        let stubBattleRound = BattleRound(
            roundNumber: 5,
            duelPairs: [DuelPair(leftCombatantId: hero.id, rightCombatantId: bot.id)]
        )

        let result = generatePairings(
            leftTeam: [hero],
            rightTeam: [bot],
            roundNumber: 5,
            playerCombatantId: hero.id,
            previousDisplayedBotSnapshot: nil,
            stubBattleRound: stubBattleRound,
            spyLogger: SpyDebugBattleLogger()
        )

        XCTAssertEqual(result.battleRound.id, stubBattleRound.id, "mutator must return exactly what DuelPairingService produced")
    }

    func testGenerateNewRoundPairings_HeroPaired_UpdatesDisplayedBotSnapshotToOpponent() {
        let hero = makeCombatant()
        let bot = makeCombatant(currentHP: 42)
        let stubBattleRound = BattleRound(
            roundNumber: 1,
            duelPairs: [DuelPair(leftCombatantId: hero.id, rightCombatantId: bot.id)]
        )
        let stalePrevious = makeCombatant(currentHP: 1)

        let result = generatePairings(
            leftTeam: [hero],
            rightTeam: [bot],
            roundNumber: 1,
            playerCombatantId: hero.id,
            previousDisplayedBotSnapshot: stalePrevious,
            stubBattleRound: stubBattleRound,
            spyLogger: SpyDebugBattleLogger()
        )

        XCTAssertEqual(result.displayedBotSnapshot?.id, bot.id)
        XCTAssertEqual(result.displayedBotSnapshot?.currentHP, 42, "must reflect the newly-paired opponent, not the stale previous snapshot")
    }

    func testGenerateNewRoundPairings_HeroUnpaired_KeepsPreviousDisplayedBotSnapshot() {
        let hero = makeCombatant()
        let waitingBot = makeCombatant()
        // Hero has no duel pair this round (e.g. waiting) — mirrors the
        // ViewModel's `if let bot = botSnapshot { displayedBotSnapshot = bot }`
        // guard: displayedBotSnapshot must be left untouched, not cleared.
        let stubBattleRound = BattleRound(
            roundNumber: 2,
            duelPairs: [],
            waitingLeftIds: [hero.id],
            waitingRightIds: [waitingBot.id]
        )
        let previous = makeCombatant(currentHP: 77)

        let result = generatePairings(
            leftTeam: [hero],
            rightTeam: [waitingBot],
            roundNumber: 2,
            playerCombatantId: hero.id,
            previousDisplayedBotSnapshot: previous,
            stubBattleRound: stubBattleRound,
            spyLogger: SpyDebugBattleLogger()
        )

        XCTAssertEqual(result.displayedBotSnapshot?.id, previous.id)
        XCTAssertEqual(result.displayedBotSnapshot?.currentHP, 77, "no hero pair this round → previous displayed snapshot must be preserved, not overwritten")
    }

    func testGenerateNewRoundPairings_ForwardsRoundStateToDebugLogger() {
        let hero = makeCombatant()
        let bot = makeCombatant()
        let stubBattleRound = BattleRound(
            roundNumber: 9,
            duelPairs: [DuelPair(leftCombatantId: hero.id, rightCombatantId: bot.id)]
        )
        let spyLogger = SpyDebugBattleLogger()

        _ = generatePairings(
            leftTeam: [hero],
            rightTeam: [bot],
            roundNumber: 9,
            playerCombatantId: hero.id,
            previousDisplayedBotSnapshot: nil,
            stubBattleRound: stubBattleRound,
            spyLogger: spyLogger
        )

        XCTAssertEqual(spyLogger.roundStateCalls.count, 1, "must forward exactly one round-state log per pairing generation")
        let call = spyLogger.roundStateCalls[0]
        XCTAssertEqual(call.roundNumber, 9)
        XCTAssertEqual(call.playerCombatantId, hero.id)
        XCTAssertEqual(call.battleRound?.id, stubBattleRound.id)
    }
}

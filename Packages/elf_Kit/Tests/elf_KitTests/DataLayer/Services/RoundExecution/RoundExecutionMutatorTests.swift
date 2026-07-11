//
//  RoundExecutionMutatorTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests the `RoundExecutionMutator` extracted from `BattleFightViewModel`'s
/// round-execution rule family (T15): the `executeFightRound` readiness
/// guard, `runRound`'s bookkeeping (round-advance vs. battle-ended), and the
/// `determineBattleOutcome` defensive-fallback wrapper. Exercised directly
/// against the injected type (via `@Dependency(\.roundExecutionMutator)`),
/// independent of `BattleFightViewModel` — `BattleFightViewModelTests` must
/// keep passing unchanged.
final class RoundExecutionMutatorTests: XCTestCase {

    // MARK: - Mocks

    /// Returns a fixed `RoundOutcome` regardless of input, so `runRound`'s
    /// bookkeeping (round-advance vs. battle-ended) can be pinned down
    /// without exercising real combat math.
    final class StubBattleRoundRunner: BattleRoundRunner, @unchecked Sendable {
        var outcome: RoundOutcome

        init(outcome: RoundOutcome) {
            self.outcome = outcome
        }

        func runRound(
            leftTeam: [CombatantSnapshot],
            rightTeam: [CombatantSnapshot],
            round: BattleRound,
            heroSelection: HeroSelection?,
            using generator: WithRandomNumberGenerator
        ) async -> RoundOutcome {
            outcome
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

    private func makeMutator() -> any RoundExecutionMutator {
        @Dependency(\.roundExecutionMutator) var mutator
        return mutator
    }

    /// `runRound` resolves its `battleRoundRunner` dependency lazily (not at
    /// mutator construction — mirrors `DefaultRoomBattleRewardMutator`'s
    /// "don't eagerly pull live-only deps" rule, see `DefaultRoundExecutionMutator`),
    /// so the stub must be in scope for the *call*, not just for `makeMutator()`.
    /// `BattleRoundRunner`'s convenience overload also resolves
    /// `\.withRandomNumberGenerator` internally before delegating to the stub;
    /// that dependency has no `testValue`, so it must be stubbed here too (same
    /// convention as `DefaultBattleRoundRunnerTests`).
    private func runRound(
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        round: BattleRound,
        heroSelection: HeroSelection?,
        currentRoundNumber: Int,
        stubOutcome: RoundOutcome
    ) async -> RoundExecutionResult {
        await withDependencies {
            $0.battleRoundRunner = StubBattleRoundRunner(outcome: stubOutcome)
            $0.withRandomNumberGenerator = WithRandomNumberGenerator(SeededRandomNumberGenerator(seed: 1))
        } operation: {
            @Dependency(\.roundExecutionMutator) var mutator
            return await mutator.runRound(
                leftTeam: leftTeam,
                rightTeam: rightTeam,
                round: round,
                heroSelection: heroSelection,
                currentRoundNumber: currentRoundNumber
            )
        }
    }

    // MARK: - canExecuteFightRound

    func testCanExecuteFightRound_PairedWithFullSelection_ReturnsTrue() {
        let mutator = makeMutator()

        let canExecute = mutator.canExecuteFightRound(
            heroIsPaired: true,
            playerAttackPoints: [.head],
            requiredAttackPoints: 1,
            playerDefensePoints: [.body, .legs],
            requiredDefensePoints: 2
        )

        XCTAssertTrue(canExecute)
    }

    func testCanExecuteFightRound_PairedWithPartialAttackSelection_ReturnsFalse() {
        let mutator = makeMutator()

        let canExecute = mutator.canExecuteFightRound(
            heroIsPaired: true,
            playerAttackPoints: [],
            requiredAttackPoints: 1,
            playerDefensePoints: [.body],
            requiredDefensePoints: 1
        )

        XCTAssertFalse(canExecute)
    }

    func testCanExecuteFightRound_PairedWithPartialDefenseSelection_ReturnsFalse() {
        let mutator = makeMutator()

        let canExecute = mutator.canExecuteFightRound(
            heroIsPaired: true,
            playerAttackPoints: [.head],
            requiredAttackPoints: 1,
            playerDefensePoints: [],
            requiredDefensePoints: 1
        )

        XCTAssertFalse(canExecute)
    }

    func testCanExecuteFightRound_Unpaired_IgnoresSelectionAndReturnsTrue() {
        let mutator = makeMutator()

        let canExecute = mutator.canExecuteFightRound(
            heroIsPaired: false,
            playerAttackPoints: [],
            requiredAttackPoints: 1,
            playerDefensePoints: [],
            requiredDefensePoints: 1
        )

        XCTAssertTrue(canExecute)
    }

    // MARK: - runRound

    func testRunRound_BattleContinues_AdvancesRoundNumberAndDoesNotEndBattle() async {
        let left = makeCombatant()
        let right = makeCombatant()
        let round = BattleRound(
            roundNumber: 1,
            duelPairs: [DuelPair(leftCombatantId: left.id, rightCombatantId: right.id)]
        )
        let stubOutcome = RoundOutcome(
            updatedLeftTeam: [left],
            updatedRightTeam: [right],
            pairResults: [],
            battleOutcome: nil
        )

        let result = await runRound(
            leftTeam: [left],
            rightTeam: [right],
            round: round,
            heroSelection: nil,
            currentRoundNumber: 3,
            stubOutcome: stubOutcome
        )

        XCTAssertFalse(result.battleEnded, "battleOutcome nil → battle continues")
        XCTAssertEqual(result.nextRoundNumber, 4, "continuing battle advances the round number by one")
    }

    func testRunRound_BattleEnds_SetsBattleEndedAndKeepsRoundNumber() async {
        let left = makeCombatant(currentHP: 0)
        let right = makeCombatant()
        let round = BattleRound(
            roundNumber: 2,
            duelPairs: [DuelPair(leftCombatantId: left.id, rightCombatantId: right.id)]
        )
        let stubOutcome = RoundOutcome(
            updatedLeftTeam: [left],
            updatedRightTeam: [right],
            pairResults: [],
            battleOutcome: .defeat
        )

        let result = await runRound(
            leftTeam: [left],
            rightTeam: [right],
            round: round,
            heroSelection: nil,
            currentRoundNumber: 2,
            stubOutcome: stubOutcome
        )

        XCTAssertTrue(result.battleEnded, "a non-nil battleOutcome ends the battle")
        XCTAssertEqual(result.nextRoundNumber, 2, "battle ended → round number does not advance")
        XCTAssertEqual(result.updatedLeftTeam.map(\.id), [left.id])
        XCTAssertEqual(result.updatedRightTeam.map(\.id), [right.id])
    }

    // MARK: - determineBattleOutcome

    func testDetermineBattleOutcome_BothSidesWiped_ForwardsDraw() {
        let mutator = makeMutator()
        let left = makeCombatant(currentHP: 0)
        let right = makeCombatant(currentHP: 0)

        XCTAssertEqual(mutator.determineBattleOutcome(left: [left], right: [right]), .draw)
    }

    func testDetermineBattleOutcome_RightWiped_ForwardsVictory() {
        let mutator = makeMutator()
        let left = makeCombatant(currentHP: 100)
        let right = makeCombatant(currentHP: 0)

        XCTAssertEqual(mutator.determineBattleOutcome(left: [left], right: [right]), .victory)
    }

    func testDetermineBattleOutcome_BothSidesAlive_DefensiveFallbackIsDraw() {
        // `finishBattle` only calls this once `battleEnded == true`, so both-alive
        // shouldn't happen in practice — but the `?? .draw` fallback must still
        // hold if it ever does (regression guard for the moved defensive default).
        let mutator = makeMutator()
        let left = makeCombatant(currentHP: 50)
        let right = makeCombatant(currentHP: 50)

        XCTAssertEqual(mutator.determineBattleOutcome(left: [left], right: [right]), .draw)
    }
}

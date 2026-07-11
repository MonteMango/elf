//
//  BattleFightViewModel_RoundExecutionAndDuelPairingDelegationTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// AC-06 real-delegation check for T17: `BattleFightViewModel`'s round
/// execution (`executeFightRound` / `runRound`) and duel-pairing
/// (`generateNewRoundPairings`, driven from `loadInitialData`) must reduce to
/// a single delegating call into the injected `RoundExecutionMutator` /
/// `DuelPairingMutator` — not reimplement the rules inline. Proven with spy
/// mutators whose canned return values are deliberately impossible for the
/// ViewModel to have produced on its own (sentinel round numbers / sentinel
/// teams / a sentinel duel round): if the ViewModel's observable post-call
/// state exactly mirrors the spy's output, it must be *using* the injected
/// value rather than computing its own.
@MainActor
final class BattleFightViewModel_RoundExecutionAndDuelPairingDelegationTests: XCTestCase {

    // MARK: - Spies

    private final class SpyRoundExecutionMutator: RoundExecutionMutator, @unchecked Sendable {
        var canExecuteReturn = true
        var canExecuteCallCount = 0

        var runRoundResult: RoundExecutionResult
        var runRoundCallCount = 0

        init(runRoundResult: RoundExecutionResult) {
            self.runRoundResult = runRoundResult
        }

        func canExecuteFightRound(
            heroIsPaired: Bool,
            playerAttackPoints: Set<BodyPart>,
            requiredAttackPoints: Int,
            playerDefensePoints: Set<BodyPart>,
            requiredDefensePoints: Int
        ) -> Bool {
            canExecuteCallCount += 1
            return canExecuteReturn
        }

        func runRound(
            leftTeam: [CombatantSnapshot],
            rightTeam: [CombatantSnapshot],
            round: BattleRound,
            heroSelection: HeroSelection?,
            currentRoundNumber: Int
        ) async -> RoundExecutionResult {
            runRoundCallCount += 1
            return runRoundResult
        }

        func determineBattleOutcome(left: [CombatantSnapshot], right: [CombatantSnapshot]) -> BattleOutcome {
            .draw
        }
    }

    private final class SpyDuelPairingMutator: DuelPairingMutator, @unchecked Sendable {
        var result: DuelPairingResult
        var callCount = 0

        init(result: DuelPairingResult) {
            self.result = result
        }

        func generateNewRoundPairings(
            leftTeam: [CombatantSnapshot],
            rightTeam: [CombatantSnapshot],
            roundNumber: Int,
            playerCombatantId: CombatantID?,
            previousDisplayedBotSnapshot: CombatantSnapshot?
        ) -> DuelPairingResult {
            callCount += 1
            return result
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

    private func makeBattle() -> Battle {
        Battle(leftTeam: [makeCombatant()], rightTeam: [makeCombatant()])
    }

    // MARK: - generateNewRoundPairings → DuelPairingMutator

    func testLoadInitialData_DelegatesToDuelPairingMutator() {
        let sentinelRound = BattleRound(roundNumber: 999, duelPairs: [])
        let sentinelDisplayed = makeCombatant(currentHP: 42)
        let spy = SpyDuelPairingMutator(
            result: DuelPairingResult(battleRound: sentinelRound, displayedBotSnapshot: sentinelDisplayed)
        )

        let vm = withDependencies {
            $0.duelPairingMutator = spy
            $0.botAI = ElfRandomBotAI()
            $0.battleLogger = ElfBattleLogger()
            $0.buffEffectsCalculator = PassthroughBuffEffectsCalculator()
            $0.equippedSlotResolver = DefaultHeroEquippedSlotResolver()
            $0.equipmentQueryService = ElfEquipmentQueryService()
            $0.duelPairingService = RandomDuelPairingService()
        } operation: { () -> BattleFightViewModel in
            let vm = BattleFightViewModel(battle: makeBattle())
            vm.loadInitialData()
            return vm
        }

        XCTAssertEqual(spy.callCount, 1)
        // The VM's observable round state exactly mirrors the spy's sentinel
        // output — proof it used the *injected* value, not one it computed
        // itself (a real pairing algorithm could never produce roundNumber
        // 999 from a fresh round-1 battle, nor this unrelated displayed
        // snapshot).
        XCTAssertEqual(vm.currentBattleRound?.roundNumber, 999)
        XCTAssertEqual(vm.displayedBotSnapshot?.currentHP, 42)
    }

    // MARK: - executeFightRound / runRound → RoundExecutionMutator

    func testExecuteFightRound_ReadinessGuard_DelegatesToMutator() async {
        let spy = SpyRoundExecutionMutator(runRoundResult: RoundExecutionResult(
            updatedLeftTeam: [], updatedRightTeam: [], pairResults: [], battleEnded: false, nextRoundNumber: 2
        ))
        spy.canExecuteReturn = false // deliberately blocks, regardless of local point selection

        await withDependencies {
            $0.roundExecutionMutator = spy
            $0.botAI = ElfRandomBotAI()
            $0.battleLogger = ElfBattleLogger()
            $0.buffEffectsCalculator = PassthroughBuffEffectsCalculator()
            $0.equippedSlotResolver = DefaultHeroEquippedSlotResolver()
            $0.equipmentQueryService = ElfEquipmentQueryService()
            $0.duelPairingService = RandomDuelPairingService()
        } operation: {
            let vm = BattleFightViewModel(battle: makeBattle())
            vm.loadInitialData()
            await vm.executeFightRound()
        }

        XCTAssertEqual(spy.canExecuteCallCount, 1)
        // Guard blocked the round — runRound must never have been reached.
        XCTAssertEqual(spy.runRoundCallCount, 0)
    }

    func testExecuteFightRound_AppliesInjectedRoundResult() async {
        let sentinelLeft = [makeCombatant(currentHP: 7)]
        let sentinelRight = [makeCombatant(currentHP: 13)]
        let spy = SpyRoundExecutionMutator(runRoundResult: RoundExecutionResult(
            updatedLeftTeam: sentinelLeft,
            updatedRightTeam: sentinelRight,
            pairResults: [],
            battleEnded: true,
            nextRoundNumber: 777
        ))
        spy.canExecuteReturn = true

        let vm = await withDependencies {
            $0.roundExecutionMutator = spy
            $0.botAI = ElfRandomBotAI()
            $0.battleLogger = ElfBattleLogger()
            $0.buffEffectsCalculator = PassthroughBuffEffectsCalculator()
            $0.equippedSlotResolver = DefaultHeroEquippedSlotResolver()
            $0.equipmentQueryService = ElfEquipmentQueryService()
            $0.duelPairingService = RandomDuelPairingService()
        } operation: { () async -> BattleFightViewModel in
            let vm = BattleFightViewModel(battle: makeBattle())
            vm.loadInitialData()
            await vm.executeFightRound()
            return vm
        }

        XCTAssertEqual(spy.runRoundCallCount, 1)
        // The VM's observable team/round state exactly mirrors the spy's
        // sentinel output — proof it applied the *injected* result rather
        // than computing its own (a real round could never jump straight to
        // round 777 from round 1).
        XCTAssertEqual(vm.leftTeam.map(\.currentHP), [7])
        XCTAssertEqual(vm.rightTeam.map(\.currentHP), [13])
        XCTAssertEqual(vm.currentRoundNumber, 777)
        XCTAssertTrue(vm.battleEnded)
    }
}

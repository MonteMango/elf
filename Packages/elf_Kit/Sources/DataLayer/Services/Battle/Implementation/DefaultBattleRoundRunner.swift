//
//  DefaultBattleRoundRunner.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

public final class DefaultBattleRoundRunner: BattleRoundRunner {

    // MARK: - Dependencies (snapshotted at init)

    private let combatRoundExecutor: any CombatRoundExecutor
    private let botAI: any BotAIService

    // MARK: - Initialization

    public init() {
        @Dependency(\.combatRoundExecutor) var combatRoundExecutor
        @Dependency(\.botAI) var botAI
        self.combatRoundExecutor = combatRoundExecutor
        self.botAI = botAI
    }

    // MARK: - Per-pair compute input

    /// Snapshot of one pair's inputs, taken on the caller's actor and sent
    /// to a child task on the cooperative pool. All fields are value types,
    /// so the struct is `Sendable`.
    private struct PairInput: Sendable {
        let index: Int
        let leftIdx: Int
        let rightIdx: Int
        let pair: DuelPair
        let left: CombatantSnapshot
        let right: CombatantSnapshot
        let leftAttack: Set<BodyPart>
        let leftDefense: Set<BodyPart>
        let rightAttack: Set<BodyPart>
        let rightDefense: Set<BodyPart>
        let isHeroPair: Bool
    }

    // MARK: - BattleRoundRunner

    public func runRound(
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        round: BattleRound,
        heroSelection: HeroSelection?
    ) async -> RoundOutcome {
        let inputs = buildPairInputs(
            leftTeam: leftTeam,
            rightTeam: rightTeam,
            round: round,
            heroSelection: heroSelection
        )

        // Capture the Sendable executor into a local before the group so
        // child task closures don't capture `self` — they only need the
        // executor.
        let executor = combatRoundExecutor

        let computed = await withTaskGroup(
            of: (PairInput, CombatRoundResult).self
        ) { group in
            for input in inputs {
                group.addTask {
                    let result = executor.executeRound(
                        playerSnapshot: input.left,
                        botSnapshot: input.right,
                        playerAttackPoints: input.leftAttack,
                        playerDefensePoints: input.leftDefense,
                        botAttackPoints: input.rightAttack,
                        botDefensePoints: input.rightDefense
                    )
                    return (input, result)
                }
            }
            var collected: [(PairInput, CombatRoundResult)] = []
            collected.reserveCapacity(inputs.count)
            for await item in group { collected.append(item) }
            return collected
        }

        let sorted = computed.sorted { $0.0.index < $1.0.index }

        var updatedLeft = leftTeam
        var updatedRight = rightTeam
        var pairResults: [PairResult] = []
        pairResults.reserveCapacity(sorted.count)

        for (input, result) in sorted {
            let leftOldHP = input.left.currentHP
            let rightOldHP = input.right.currentHP
            let leftNewHP = max(0, leftOldHP - result.playerDamageTaken)
            let rightNewHP = max(0, rightOldHP - result.botDamageTaken)
            updatedLeft[input.leftIdx].currentHP = leftNewHP
            updatedRight[input.rightIdx].currentHP = rightNewHP

            updatedLeft[input.leftIdx].currentEP = max(0, input.left.currentEP - result.playerEPSpent)
            updatedRight[input.rightIdx].currentEP = max(0, input.right.currentEP - result.botEPSpent)

            pairResults.append(PairResult(
                pair: input.pair,
                leftSnapshot: input.left,
                rightSnapshot: input.right,
                leftAttack: input.leftAttack,
                leftDefense: input.leftDefense,
                rightAttack: input.rightAttack,
                rightDefense: input.rightDefense,
                result: result,
                leftOldHP: leftOldHP,
                leftNewHP: leftNewHP,
                rightOldHP: rightOldHP,
                rightNewHP: rightNewHP,
                isHeroPair: input.isHeroPair
            ))
        }

        return RoundOutcome(
            updatedLeftTeam: updatedLeft,
            updatedRightTeam: updatedRight,
            pairResults: pairResults,
            battleOutcome: detectBattleOutcome(left: updatedLeft, right: updatedRight)
        )
    }

    // MARK: - Private helpers

    private func buildPairInputs(
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        round: BattleRound,
        heroSelection: HeroSelection?
    ) -> [PairInput] {
        var inputs: [PairInput] = []
        inputs.reserveCapacity(round.duelPairs.count)

        for (index, pair) in round.duelPairs.enumerated() {
            guard
                let leftIdx = leftTeam.firstIndex(where: { $0.id == pair.leftCombatantId }),
                let rightIdx = rightTeam.firstIndex(where: { $0.id == pair.rightCombatantId })
            else { continue }

            let left = leftTeam[leftIdx]
            let right = rightTeam[rightIdx]
            let isHeroPair = (heroSelection?.combatantId == left.id)

            let leftAttack: Set<BodyPart>
            let leftDefense: Set<BodyPart>
            if isHeroPair, let hero = heroSelection {
                leftAttack = hero.attackPoints
                leftDefense = hero.defensePoints
            } else {
                leftAttack = botAI.selectAttackPoints(count: left.attackPoints)
                leftDefense = botAI.selectDefensePoints(count: left.defensePoints)
            }
            let rightAttack = botAI.selectAttackPoints(count: right.attackPoints)
            let rightDefense = botAI.selectDefensePoints(count: right.defensePoints)

            inputs.append(PairInput(
                index: index,
                leftIdx: leftIdx,
                rightIdx: rightIdx,
                pair: pair,
                left: left,
                right: right,
                leftAttack: leftAttack,
                leftDefense: leftDefense,
                rightAttack: rightAttack,
                rightDefense: rightDefense,
                isHeroPair: isHeroPair
            ))
        }
        return inputs
    }
}

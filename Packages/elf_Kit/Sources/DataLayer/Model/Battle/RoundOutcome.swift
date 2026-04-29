//
//  RoundOutcome.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Result of running a single battle round through `BattleRoundRunner`.
///
/// `updatedLeftTeam` / `updatedRightTeam` are the input teams with HP changes
/// already applied — the runner does not mutate input arrays, so consumers
/// swap their current state with these.
///
/// `pairResults` lists every pair in the original `BattleRound.duelPairs`
/// order. For 1v1 callers (`AutoBattleViewModel`,
/// `ElfBattleSimulationService`) it's a single-element array.
///
/// `battleOutcome` is `nil` while at least one combatant survives on each
/// side; otherwise the final outcome.
public struct RoundOutcome: Sendable {
    public let updatedLeftTeam: [CombatantSnapshot]
    public let updatedRightTeam: [CombatantSnapshot]
    public let pairResults: [PairResult]
    public let battleOutcome: BattleOutcome?

    public init(
        updatedLeftTeam: [CombatantSnapshot],
        updatedRightTeam: [CombatantSnapshot],
        pairResults: [PairResult],
        battleOutcome: BattleOutcome?
    ) {
        self.updatedLeftTeam = updatedLeftTeam
        self.updatedRightTeam = updatedRightTeam
        self.pairResults = pairResults
        self.battleOutcome = battleOutcome
    }
}

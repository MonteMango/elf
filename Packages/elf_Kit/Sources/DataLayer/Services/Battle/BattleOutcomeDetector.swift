//
//  BattleOutcomeDetector.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Inspects the alive flags on both teams and returns the corresponding
/// `BattleOutcome`, or `nil` if the battle should continue (both sides still
/// have at least one alive combatant).
///
/// Used by `BattleRoundRunner` to set `RoundOutcome.battleOutcome`, and by
/// `BattleFightViewModel.determineBattleOutcome()` to settle the final
/// outcome at battle end.
public func detectBattleOutcome(
    left: [CombatantSnapshot],
    right: [CombatantSnapshot]
) -> BattleOutcome? {
    let leftAlive = left.contains(where: { $0.isAlive })
    let rightAlive = right.contains(where: { $0.isAlive })
    switch (leftAlive, rightAlive) {
    case (true, true):   return nil
    case (true, false):  return .victory
    case (false, true):  return .defeat
    case (false, false): return .draw
    }
}

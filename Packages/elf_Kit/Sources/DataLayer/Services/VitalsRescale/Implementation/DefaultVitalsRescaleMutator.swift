//
//  DefaultVitalsRescaleMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Default `VitalsRescaleMutator`. Mirrors the rule formerly inlined on
/// `BattleFightViewModel.rescaleCurrentVitals`/`scaledVital`.
public struct DefaultVitalsRescaleMutator: VitalsRescaleMutator {

    public init() {}

    public func rescaleVitals(combatant: inout CombatantSnapshot, before: HeroAttributes, after: HeroAttributes) {
        combatant.currentHP = scaledVital(
            current: combatant.currentHP,
            oldMax: before.hitPoints.intValue,
            newMax: after.hitPoints.intValue
        )
        combatant.currentMP = scaledVital(
            current: combatant.currentMP,
            oldMax: before.manaPoints.intValue,
            newMax: after.manaPoints.intValue
        )
    }

    /// Half-up integer scaling of `current` from `oldMax` to `newMax`, clamped
    /// to `[0, newMax]`. `oldMax == 0` short-circuits to `min(current, newMax)`
    /// — preserves a dead combatant (current == 0) and avoids ÷0.
    private func scaledVital(current: Int, oldMax: Int, newMax: Int) -> Int {
        guard oldMax > 0 else { return max(0, min(current, newMax)) }
        let scaled = (current * newMax + oldMax / 2) / oldMax
        return max(0, min(scaled, newMax))
    }
}

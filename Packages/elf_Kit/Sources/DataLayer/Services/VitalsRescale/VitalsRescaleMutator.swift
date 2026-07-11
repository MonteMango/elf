//
//  VitalsRescaleMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Rule family for proportionally rescaling a combatant's current HP/MP after
/// a buff shifts the effective cap, extracted from `BattleFightViewModel`
/// (T21, architecture-hardening review finding #1): `applyBattleBuff`'s
/// vitals-rescale logic.
public protocol VitalsRescaleMutator: Sendable {

    /// Rescales `combatant.currentHP`/`currentMP` proportionally so the
    /// fraction-of-cap is preserved across the `before` → `after` effective
    /// attribute shift (e.g. 50/100 HP + a buff raising the cap to 120 → 60/120).
    func rescaleVitals(combatant: inout CombatantSnapshot, before: HeroAttributes, after: HeroAttributes)
}

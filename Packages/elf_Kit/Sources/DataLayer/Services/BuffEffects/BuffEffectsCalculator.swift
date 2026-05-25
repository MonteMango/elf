//
//  BuffEffectsCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Folds the effects of an `AppliedBuff` collection into a `HeroAttributes`
/// value.
///
/// Algorithm (iteration 1):
/// 1. Sum all `.combatAttributesFlat` deltas into the combat-attribute
///    fields of `base`, and `.vitalsFlat` deltas into the HP/MP fields.
/// 2. Sum all `.combatAttributesPercent` values; apply the resulting multiplier
///    `(1 + sum)` to the five combat attributes only (strength, agility,
///    power, instinct, endurance). HP/MP are not modified by percent.
/// 3. `stacks` multiplies each effect (so `exhausted` with `stacks == 2` and
///    `stackingRule == .stack` contributes `2 × -0.30 = -0.60`).
///
/// The calculator does not distinguish global from battle scope — math is
/// identical. Callers feed both collections via `effectiveAttributes(of:)`
/// or by concatenating at the use site.
///
/// Resolution of `buffId` → `Buff` is done via `BuffsRepository`.
public protocol BuffEffectsCalculator: Sendable {
    func apply(buffs: [AppliedBuff], to base: HeroAttributes) -> HeroAttributes
}

extension BuffEffectsCalculator {

    /// Buff-folded view of a snapshot's `baseHeroAttributes`. Convenience
    /// over `apply(buffs:to:)` — concatenates the snapshot's global and
    /// battle buff collections. The unpacking is mechanical and identical
    /// for every conformer, so this lives in an extension rather than on the
    /// protocol surface.
    ///
    /// Flat buffs are split by target: `BuffEffect.combatAttributesFlat`
    /// contributes to the five combat attributes; `BuffEffect.vitalsFlat`
    /// contributes to HP/MP. Percent buffs (`BuffEffect.combatAttributesPercent`)
    /// scale the five combat attributes only — HP and MP are not multiplied.
    /// Use this to derive effective HP/MP caps and per-strike combat math.
    public func effectiveAttributes(of snapshot: CombatantSnapshot) -> HeroAttributes {
        apply(buffs: snapshot.globalBuffs + snapshot.battleBuffs, to: snapshot.baseHeroAttributes)
    }
}

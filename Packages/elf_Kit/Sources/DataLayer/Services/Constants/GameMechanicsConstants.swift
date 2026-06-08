//
//  GameMechanicsConstants.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Constants for game mechanics tuning
///
/// These values control probabilities, distributions, and other game balance parameters.
internal enum GameMechanicsConstants {

    // MARK: - Distribution Peak Positions

    /// Position of the tent peak inside the rolled stage-1 chance range
    /// `[stat - opponentInstinct ... min(stat, 100)]`, expressed as a fraction
    /// from minimum (0.0) to maximum (1.0).
    ///
    /// - `0.0` → peak at **minimum** (worst-case chance is most likely)
    /// - `0.5` → peak in the middle of the range
    /// - `1.0` → peak at **maximum** (best-case chance is most likely)
    ///
    /// **How much weight the peak takes** is controlled separately via
    /// `critPeakWeight`. The position only decides *where* the bump is; the
    /// share of probability that bump claims is fixed by the weight constant
    /// and no longer depends on range size.
    internal static let critPeakPosition: Double = 0.0

    /// See `critPeakPosition` for the meaning of this value. Weight is
    /// controlled separately via `dodgePeakWeight`.
    internal static let dodgePeakPosition: Double = 0.0

    // MARK: - Distribution Peak Weights

    /// Fraction of total probability mass that goes to the peak value in
    /// crit's stage-1 distribution (0.0 – just-below-1.0). The remaining
    /// `1 - critPeakWeight` is split among non-peak values with a linear
    /// falloff from the peak toward both ends (floor 1).
    ///
    /// - `0.0` → peak is selected 0% (other values fully take over)
    /// - `0.5` → peak selected 50%, other 50% spreads linearly
    /// - `0.6` → peak selected 60%, other 40% spreads linearly (current value)
    ///
    /// Unlike the previous integer-tent weighting, the peak's share no
    /// longer depends on `rangeSize` — `0.6` always means 60% regardless of
    /// how wide the rolled range is.
    internal static let critPeakWeight: Double = 0.6

    /// Fraction of total probability mass that goes to the peak value in
    /// dodge's stage-1 distribution. See `critPeakWeight` for semantics.
    internal static let dodgePeakWeight: Double = 0.6

    // MARK: - Intuition Suppression Multipliers

    /// Base multiplier applied to **attacker's intuition** when computing
    /// dodge chance range. Final multiplier scales with attacker level:
    /// `multiplier = base + perLevel × attackerLevel`.
    /// Formula:
    /// `range = [agility − round(instinct × multiplier), min(100, agility)]`.
    ///
    /// At `base = 0.8` + `perLevel = 0.04`:
    /// - L1 → 0.84 (sub-1.0, low-level dodgers barely suppressed)
    /// - L3 → 0.92
    /// - L6 → 1.04
    /// - L12 → 1.28 (high-level intuition crushes agility)
    internal static let dodgeIntuitionSuppressionBaseMultiplier: Double = 0.8

    /// Per-attacker-level addition to `dodgeIntuitionSuppressionBaseMultiplier`.
    /// See `dodgeIntuitionSuppressionBaseMultiplier` for the formula.
    internal static let dodgeIntuitionSuppressionPerLevelDelta: Double = 0.04

    /// Base multiplier applied to **defender's intuition** when computing
    /// crit chance range. Mirrors the dodge mechanic but with shallower
    /// slope — crit is a damage-amp stat (less binary than dodge), so the
    /// level scaling is gentler.
    /// Formula:
    /// `range = [power − round(instinct × multiplier), min(100, power)]`.
    ///
    /// At `base = 0.8` + `perLevel = 0.024`:
    /// - L1 → 0.824 (low-level crits easier to land)
    /// - L3 → 0.872
    /// - L6 → 0.944
    /// - L12 → 1.088 (defender's int harder-suppresses crit at high levels)
    ///
    /// Goal: low-level crit gets more spike potential (helps `crit > def`
    /// at L3); high-level def's intuition suppresses crit (helps cap the
    /// `crit > def` overshoot).
    internal static let critIntuitionSuppressionBaseMultiplier: Double = 0.8

    /// Per-attacker-level addition to `critIntuitionSuppressionBaseMultiplier`.
    internal static let critIntuitionSuppressionPerLevelDelta: Double = 0.024

    // MARK: - Crit Multiplier Distribution

    /// Default crit multiplier values
    internal static let critMultiplierValues: [Double] = [0.75, 1.00, 1.25, 1.5, 2.0, 3.0]

    /// Weights for crit multiplier distribution. Paired with
    /// `critMultiplierValues = [0.75, 1.00, 1.25, 1.5, 2.0, 3.0]`.
    /// Mean ≈ `0.10·1.0 + 0.25·1.25 + 0.35·1.5 + 0.20·2.0 + 0.10·3.0 = 1.6375×`.
    /// Applied to both unblocked AND blocked crits — the historical
    /// `blockedCritMultiplierWeights` downgrade was removed because the
    /// EP-amplification (`critEPCostBonusRatio`) already taxes blocked
    /// crits at the resource layer.
    internal static let critMultiplierWeights: [Int] = [0, 10, 25, 35, 20, 10]

    /// Multiplier applied to the **post-armor** damage of a weak block —
    /// the special path where an Exhausted defender at 0 EP still puts a
    /// guard up. They pay no EP (have none to spend) but absorb the strike
    /// at this fraction. `0.6` = defender takes 60 % of the would-be damage
    /// (weak block soaks 40 %).
    ///
    /// Applied **only on the no-crit branch** of weak block: full damage
    /// chain (weapon + strength − endurance − armor, clamped at 0) is then
    /// multiplied by this value.
    internal static let exhaustedBlockDamageMultiplier: Double = 0.6

    // MARK: - Character Creation

    /// Starting level for newly created characters
    internal static let startingLevel: Int16 = 1

    // MARK: - Endurance Points (EP)

    /// Starting EP pool for every combatant (hero or monster).
    internal static let startingEP: Int = 2400

    /// How many *extra effective blocks* one Endurance attribute point grants,
    /// independent of weapon.
    ///
    /// Used by `ElfEnduranceService.calculateBlockCost`:
    /// `cost = pool / max(1, pool/baseCost + endurance × blocksPerEndurancePoint
    ///                       − attackerStrength × blocksLostPerAttackerStrength)`
    ///
    /// Examples (2H weapon, baseCost 400, pool 2400, attacker str 12):
    /// - `0.3` (current): 36 Endurance → denom 15.6 → cost 154 EP (15.6 blocks)
    /// - `0.4`: 36 Endurance → denom 19.2 → cost 125 EP (19.2 blocks)
    /// - `0.5`: 36 Endurance → denom 22.8 → cost 105 EP (22.8 blocks)
    internal static let blocksPerEndurancePoint: Double = 0.3

    /// How many *effective blocks the defender loses* per point of attacker's
    /// Strength. Symmetric counterpart to `blocksPerEndurancePoint` —
    /// Endurance grants extra blocks, Strength burns them away. Same
    /// "blocks" abstraction so both knobs are read in the same units.
    ///
    /// Used by `ElfEnduranceService.calculateBlockCost`:
    /// `cost = pool / max(1, pool/baseCost + endurance × blocksPerEndurancePoint − attackerStrength × blocksLostPerAttackerStrength)`
    ///
    /// Examples (2H weapon, baseCost 400, pool 2400, attacker str 12 at L12,
    /// defender end 36 → pool/baseCost = 6, end-bonus = 10.8):
    /// - `0.1` (current): blocks lost = 1.2; denom = 6 + 10.8 − 1.2 = 15.6, cost ≈ 154 EP
    /// - `0.2`: blocks lost = 2.4; denom = 6 + 10.8 − 2.4 = 14.4, cost ≈ 167 EP
    /// - `0.5`: blocks lost = 6.0; denom = 6 + 10.8 − 6.0 = 10.8, cost ≈ 222 EP
    ///
    /// At `0.1` the impact on def is mild (~10 EP/block), but on a
    /// zero-endurance defender (dodge/crit) the same str pressure changes
    /// blockCost from 400 EP (no str) to ~500 EP (str 12), exhausting them
    /// noticeably faster — the asymmetry is where the lever bites.
    internal static let blocksLostPerAttackerStrength: Double = 0.1

    // MARK: - Damage reduction coefficients (sqrt-curve)

    /// `mean_reduction_from_INT = sqrt(int) × 0.12`. Each INT point absorbs
    /// **20 %** of what the same-valued STR point would deal in damage
    /// (`0.6 × 0.2 = 0.12`). Mirror shape of strength's sqrt curve.
    internal static let intuitionReductionCoefficient: Double = 0.12

    /// `mean_reduction_from_END = sqrt(end) × 0.18`. Each END point absorbs
    /// **30 %** of what the same-valued STR point would deal
    /// (`0.6 × 0.3 = 0.18`) — Endurance is the dedicated tank stat, so it
    /// gets 1.5× the per-point reduction of Intuition. Stacks additively
    /// with the intuition roll inside the combat calculator.
    internal static let enduranceReductionCoefficient: Double = 0.18

    /// Fraction of (crit multiplier − 1) that converts the weapon's
    /// **baseCost** into a flat "crit tax" when a crit lands on a blocked
    /// body part. Models the extra effort of parrying a critical strike —
    /// bigger crits eat more EP, faster Exhaustion for the defender.
    ///
    /// Formula (in `ElfSnapshotCombatCalculator.resolveDefendedAttack`):
    /// ```
    /// critEPTax       = baseCost × (multiplier − 1) × ratio
    /// actualBlockCost = max(1, blockCost + critEPTax)
    /// ```
    /// where `blockCost` is the normal endurance- and attacker-strength-
    /// adjusted cost from `EnduranceService.calculateBlockCost`.
    ///
    /// With ratio `1.0` (tax on top of the normal cost):
    ///   - 1.25× crit: + baseCost × 0.25
    ///   - 1.5× crit: + baseCost × 0.5
    ///   - 2.0× crit: + baseCost × 1.0
    ///   - 3.0× crit: + baseCost × 2.0
    ///
    /// **Why a flat tax (not proportional amplification):** algebraically
    /// identical to "amplify baseCost, then subtract the defender's flat
    /// Endurance saving". Endurance gives a *fixed* EP saving per block;
    /// the crit tax doesn't shrink with it, so the mechanic actually bites
    /// high-Endurance defenders (sim step 55-56: proportional amplification
    /// barely registered on def's EP economy; with the flat model def's EP
    /// usage finally scales meaningfully with crit frequency). It also
    /// composes cleanly with attacker-strength pressure: when strength
    /// pushes `blockCost` above `baseCost`, the tax still adds on top — no
    /// accidental discount.
    ///
    /// Applied **only on the successful-block path** — weak-block
    /// (Exhausted) and undefended hits are unaffected.
    internal static let critEPCostBonusRatio: Double = 1.0

    // MARK: - Calendar

    /// Number of upcoming days to show in the calendar preview
    internal static let upcomingDaysCount: Int = 3
}

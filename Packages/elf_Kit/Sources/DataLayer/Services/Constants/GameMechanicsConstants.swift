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
enum GameMechanicsConstants {

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
    static let critPeakPosition: Double = 0.0

    /// See `critPeakPosition` for the meaning of this value. Weight is
    /// controlled separately via `dodgePeakWeight`.
    static let dodgePeakPosition: Double = 0.0

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
    static let critPeakWeight: Double = 0.6

    /// Fraction of total probability mass that goes to the peak value in
    /// dodge's stage-1 distribution. See `critPeakWeight` for semantics.
    static let dodgePeakWeight: Double = 0.6

    // MARK: - Crit Multiplier Distribution

    /// Default crit multiplier values
    static let critMultiplierValues: [Double] = [0.75, 1.00, 1.25, 1.5, 2.0, 3.0]

    /// Default weights for crit multiplier distribution
    static let critMultiplierWeights: [Int] = [0, 15, 30, 40, 10, 5]

    /// Weights for the multiplier rolled when a crit lands on a **blocked**
    /// body part. Paired with `critMultiplierValues` (same index order):
    /// `[0.75, 1.00, 1.25, 1.5, 2.0, 3.0]`. The block downgrades the crit's
    /// damage scaling — most weight sits at 1.0× (block fully cancels crit
    /// bonus) and 1.25× (slight leak through), with rare 0.75× (block
    /// absorbs some normal hit too) and 1.5× tail. The 2.0× / 3.0× bands are
    /// closed (weight 0) so a blocked crit can never spike harder than a
    /// non-crit big-multiplier hit. Defender still pays the block's EP cost.
    ///
    /// Mean ≈ `0.05·0.75 + 0.5·1.0 + 0.4·1.25 + 0.05·1.5 = 1.1125×`.
    ///
    /// The `PointStatus.critHit` case is kept so the UI renders the crit
    /// indicator and statistics record a crit success — only the damage
    /// scaling differs from the unblocked roll.
    static let blockedCritMultiplierWeights: [Int] = [5, 50, 40, 5, 0, 0]

    /// Multiplier applied to the **post-armor** damage of a weak block —
    /// the special path where an Exhausted defender at 0 EP still puts a
    /// guard up. They pay no EP (have none to spend) but absorb the strike
    /// at this fraction. `0.6` = defender takes 60 % of the would-be damage
    /// (weak block soaks 40 %).
    ///
    /// Applied **only on the no-crit branch** of weak block: full damage
    /// chain (weapon + strength − endurance − armor, clamped at 0) is then
    /// multiplied by this value.
    ///
    /// On the crit branch the calculator instead rolls
    /// `blockedCritMultiplierWeights` to downgrade the crit multiplier —
    /// that IS the penalty for the attacker there, and this value does NOT
    /// stack on top (no double-dip).
    static let exhaustedBlockDamageMultiplier: Double = 0.6

    // MARK: - Character Creation

    /// Starting level for newly created characters
    static let startingLevel: Int16 = 1

    // MARK: - Endurance Points (EP)

    /// Starting EP pool for every combatant (hero or monster).
    static let startingEP: Int = 2400

    /// How many *extra effective blocks* one Endurance attribute point grants,
    /// independent of weapon. The default `0.5` matches the canonical design
    /// rule "+2 Endurance = +1 effective block".
    ///
    /// Used by `ElfEnduranceService.calculateBlockCost`:
    /// `cost = pool / (pool / baseCost + endurance × blocksPerEndurancePoint)`
    ///
    /// Examples (1H weapon, baseCost 200, pool 2000):
    /// - `0.5` (default): 36 Endurance → cost 71 EP (28 blocks)
    /// - `0.4`: 36 Endurance → cost 81 EP (24 blocks); each Endurance adds 0.4 blocks
    /// - `0.25`: 36 Endurance → cost 105 EP (19 blocks); each Endurance adds 0.25 blocks
    static let blocksPerEndurancePoint: Double = 0.4

    // MARK: - Calendar

    /// Number of upcoming days to show in the calendar preview
    static let upcomingDaysCount: Int = 3
}

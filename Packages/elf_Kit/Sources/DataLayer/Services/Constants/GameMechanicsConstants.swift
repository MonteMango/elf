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

    /// Multiplier applied to a crit that landed on a **blocked** body part.
    /// The crit still succeeded — `PointStatus.critHit` is kept so the UI
    /// renders the crit indicator and statistics record a crit success —
    /// but the damage is scaled by this value instead of the rolled
    /// multiplier. `1.0` means a blocked crit deals exactly normal-hit
    /// damage (block fully cancels the crit bonus); anything below `1.0`
    /// (e.g. `0.5`) would let the block partially "absorb" even the
    /// normal hit. The defender still pays the block's EP cost.
    static let blockedCritMultiplier: Double = 1.0

    // MARK: - Character Creation

    /// Starting level for newly created characters
    static let startingLevel: Int16 = 1

    // MARK: - Endurance Points (EP)

    /// Starting EP pool for every combatant (hero or monster).
    static let startingEP: Int = 2000

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
    static let blocksPerEndurancePoint: Double = 0.5

    // MARK: - Calendar

    /// Number of upcoming days to show in the calendar preview
    static let upcomingDaysCount: Int = 3
}

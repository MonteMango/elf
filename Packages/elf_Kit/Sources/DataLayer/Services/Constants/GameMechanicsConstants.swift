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

    /// Peak position for crit chance distribution (0.0 - 1.0)
    ///
    /// - 0.0: Peak at minimum chance (favors lower crit chances)
    /// - 1.0: Peak at maximum chance (favors higher crit chances)
    /// - 0.5: Peak in the middle
    ///
    /// Example with Power=36, Instinct=9 (range 27-36):
    /// - peakPosition=0.0 → peak at 27%
    /// - peakPosition=1.0 → peak at 36%
    /// - peakPosition=0.8 → peak at ~34%
    static let critPeakPosition: Double = 0.2

    /// Peak position for dodge chance distribution (0.0 - 1.0)
    ///
    /// - 0.0: Peak at minimum chance (favors lower dodge chances)
    /// - 1.0: Peak at maximum chance (favors higher dodge chances)
    /// - 0.5: Peak in the middle
    ///
    /// Example with Agility=36, Instinct=9 (range 27-36):
    /// - peakPosition=0.0 → peak at 27%
    /// - peakPosition=1.0 → peak at 36%
    /// - peakPosition=0.8 → peak at ~34%
    static let dodgePeakPosition: Double = 0.4

    // MARK: - Crit Multiplier Distribution

    /// Default crit multiplier values
    ///
    /// Available multipliers for critical hits, from weakest to strongest.
    /// - 0.75: Reduced damage (weaker than normal hit)
    /// - 1.00: Normal damage
    /// - 1.25: Light crit
    /// - 1.50: Medium crit
    /// - 2.00: Strong crit
    /// - 3.00: Devastating crit
    static let critMultiplierValues: [Double] = [0.75, 1.00, 1.25, 1.5, 2.0, 3.0]

    /// Default weights for crit multiplier distribution
    ///
    /// Higher weights = higher probability of selection.
    /// - Index 0 (0.75x): 0 weight (0%)
    /// - Index 1 (1.00x): 5 weight (5%)
    /// - Index 2 (1.25x): 15 weight (15%)
    /// - Index 3 (1.50x): 40 weight (40%)
    /// - Index 4 (2.00x): 30 weight (30%)
    /// - Index 5 (3.00x): 10 weight (10%)
    static let critMultiplierWeights: [Int] = [0, 5, 15, 40, 30, 10]

    // MARK: - Crit Multiplier Reduction (Agility-based)

    /// Coefficient for calculating crit multiplier reduction based on defender's agility
    ///
    /// Formula: `critMultiplierDecreaser = ((agility * coefficient) - power) / agility`
    ///
    /// - If decreaser <= 0: No weight redistribution
    /// - If decreaser >= 1: Maximum redistribution (100% taken from high multipliers)
    ///
    /// Example with agility=36, power=36, coefficient=1.5:
    /// - decreaser = ((36 * 1.5) - 36) / 36 = 18/36 = 0.5
    /// - This means 50% of weights are redistributed from high to low multipliers
    static let critMultiplierAgilityCoefficient: Double = 1.8

    // MARK: - Character Creation

    /// Starting level for newly created characters
    static let startingLevel: Int16 = 1

    // MARK: - Calendar

    /// Number of upcoming days to show in the calendar preview
    static let upcomingDaysCount: Int = 3
}

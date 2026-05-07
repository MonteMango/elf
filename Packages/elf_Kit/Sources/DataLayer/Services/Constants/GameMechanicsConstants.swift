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
    static let critPeakPosition: Double = 0.2

    /// Peak position for dodge chance distribution (0.0 - 1.0)
    static let dodgePeakPosition: Double = 0.4

    // MARK: - Crit Multiplier Distribution

    /// Default crit multiplier values
    static let critMultiplierValues: [Double] = [0.75, 1.00, 1.25, 1.5, 2.0, 3.0]

    /// Default weights for crit multiplier distribution
    static let critMultiplierWeights: [Int] = [0, 5, 15, 40, 30, 10]

    // MARK: - Crit Multiplier Reduction (Agility-based)

    /// Coefficient for calculating crit multiplier reduction based on defender's agility
    static let critMultiplierAgilityCoefficient: Double = 1.8

    // MARK: - Character Creation

    /// Starting level for newly created characters
    static let startingLevel: Int16 = 1

    // MARK: - Endurance Points (EP)

    /// Starting EP pool for every combatant (hero or monster).
    static let startingEP: Int = 2000

    // MARK: - Calendar

    /// Number of upcoming days to show in the calendar preview
    static let upcomingDaysCount: Int = 3
}

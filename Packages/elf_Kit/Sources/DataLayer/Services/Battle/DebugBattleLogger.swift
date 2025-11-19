//
//  DebugBattleLogger.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Service for detailed debug logging of battle calculations
///
/// This protocol provides methods to log all intermediate battle calculations
/// for debugging purposes. Implementations can output to console, files, or
/// be no-op for production builds.
///
/// **Usage**:
/// - Debug builds: Use `ConsoleDebugBattleLogger` for detailed console output
/// - Production builds: Use `NoOpDebugBattleLogger` for zero overhead
public protocol DebugBattleLogger: Sendable {

    /// Logs the start of a battle round with hero stats and selections
    ///
    /// - Parameters:
    ///   - roundNumber: Current round number
    ///   - player: Player's hero with all stats
    ///   - bot: Bot's hero with all stats
    ///   - playerAttack: Player's selected attack points
    ///   - playerDefense: Player's selected defense points
    ///   - botAttack: Bot's selected attack points
    ///   - botDefense: Bot's selected defense points
    func logRoundStart(
        roundNumber: Int,
        player: ElfHero,
        bot: ElfHero,
        playerAttack: [BodyPart],
        playerDefense: [BodyPart],
        botAttack: [BodyPart],
        botDefense: [BodyPart]
    )

    /// Logs strength damage calculation with distribution details
    ///
    /// - Parameters:
    ///   - hero: Hero name ("Player" or "Bot")
    ///   - strength: Total strength attribute
    ///   - distribution: Array of possible damage values
    ///   - weights: Corresponding weights for each value
    ///   - selectedValue: The randomly selected damage value
    func logStrengthDamage(
        hero: String,
        strength: Int16,
        distribution: [Int16],
        weights: [Int],
        selectedValue: Int16
    )

    /// Logs weapon damage calculation
    ///
    /// - Parameters:
    ///   - hero: Hero name ("Player" or "Bot")
    ///   - hand: Which hand ("left" or "right")
    ///   - weaponName: Name of the weapon
    ///   - minDamage: Minimum weapon damage
    ///   - maxDamage: Maximum weapon damage
    ///   - selectedValue: The randomly selected damage value
    func logWeaponDamage(
        hero: String,
        hand: String,
        weaponName: String,
        minDamage: Int16,
        maxDamage: Int16,
        selectedValue: Int16
    )

    /// Logs dodge calculation with both stages
    ///
    /// - Parameters:
    ///   - defender: Defender name ("Player" or "Bot")
    ///   - result: Complete dodge calculation result with all intermediate values
    ///   - agility: Defender's total agility
    ///   - instinct: Attacker's total instinct
    func logDodgeCalculation(
        defender: String,
        result: DodgeCalculationResult,
        agility: Int16,
        instinct: Int16
    )

    /// Logs critical hit check
    ///
    /// - Parameters:
    ///   - attacker: Attacker name ("Player" or "Bot")
    ///   - power: Attacker's total power
    ///   - defenderInstinct: Defender's total instinct
    ///   - critChance: Calculated crit chance (0-100)
    ///   - roll: Random roll result (1-100)
    ///   - isCrit: Whether crit succeeded
    ///   - multiplier: Damage multiplier applied (1.5 or 2.0)
    func logCritCheck(
        attacker: String,
        power: Int16,
        defenderInstinct: Int16,
        critChance: Int,
        roll: Int,
        isCrit: Bool,
        multiplier: Double
    )

    /// Logs body part calculation summary
    ///
    /// - Parameters:
    ///   - attacker: Attacker name ("Player" or "Bot")
    ///   - defender: Defender name ("Player" or "Bot")
    ///   - bodyPart: Body part being calculated
    ///   - isAttacked: Whether this body part is being attacked
    ///   - isDefended: Whether this body part is being defended
    ///   - baseDamage: Base damage before armor and multipliers
    ///   - armor: Armor value for this body part
    ///   - finalDamage: Final damage after all calculations
    ///   - finalStatus: Final point status result
    func logBodyPartCalculation(
        attacker: String,
        defender: String,
        bodyPart: BodyPart,
        isAttacked: Bool,
        isDefended: Bool,
        baseDamage: Int?,
        armor: Int?,
        finalDamage: Int?,
        finalStatus: PointStatus
    )

    /// Logs the end of a battle round with results
    ///
    /// - Parameters:
    ///   - roundNumber: Current round number
    ///   - playerOldHP: Player's HP before damage
    ///   - playerNewHP: Player's HP after damage
    ///   - botOldHP: Bot's HP before damage
    ///   - botNewHP: Bot's HP after damage
    ///   - playerResults: Player's point statuses for this round
    ///   - botResults: Bot's point statuses for this round
    func logRoundEnd(
        roundNumber: Int,
        playerOldHP: Int,
        playerNewHP: Int,
        botOldHP: Int,
        botNewHP: Int,
        playerResults: [BodyPart: PointStatus],
        botResults: [BodyPart: PointStatus]
    )
}

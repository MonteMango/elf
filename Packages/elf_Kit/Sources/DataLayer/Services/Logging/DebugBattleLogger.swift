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
/// Use `ConsoleDebugBattleLogger` with specific categories to enable logging,
/// or with an empty set for zero output.
public protocol DebugBattleLogger: Sendable {

    /// Logs the start of a battle round with combatant stats and selections
    ///
    /// - Parameters:
    ///   - roundNumber: Current round number
    ///   - playerSnapshot: Player's combatant snapshot with all stats
    ///   - botSnapshot: Bot's combatant snapshot with all stats
    ///   - playerAttack: Player's selected attack points
    ///   - playerDefense: Player's selected defense points
    ///   - botAttack: Bot's selected attack points
    ///   - botDefense: Bot's selected defense points
    func logRoundStart(
        roundNumber: Int,
        playerSnapshot: CombatantSnapshot,
        botSnapshot: CombatantSnapshot,
        playerAttack: [BodyPart],
        playerDefense: [BodyPart],
        botAttack: [BodyPart],
        botDefense: [BodyPart]
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

    /// Logs critical hit calculation with three stages
    ///
    /// - Parameters:
    ///   - attacker: Attacker name ("Player" or "Bot")
    ///   - result: Complete crit calculation result with all intermediate values
    ///   - power: Attacker's total power
    ///   - instinct: Defender's total instinct
    func logCritCalculation(
        attacker: String,
        result: CritCalculationResult,
        power: Int16,
        instinct: Int16
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

    /// Logs a snapshot of the current round: alive counts, per-combatant HP,
    /// duel pairs, waiting lists, and hero flags. Triggered after the pairing
    /// service produces a new `BattleRound`. Gated by `.roundState` category.
    ///
    /// - Parameters:
    ///   - roundNumber: Current round number
    ///   - leftTeam: Full left-team snapshots (alive + dead) with current HP
    ///   - rightTeam: Full right-team snapshots (alive + dead) with current HP
    ///   - playerCombatantId: Identity of the player-controlled combatant, if any
    ///   - battleRound: Pairing/waiting state for the round, if available
    func logRoundState(
        roundNumber: Int,
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        playerCombatantId: UUID?,
        battleRound: BattleRound?
    )
}

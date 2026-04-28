//
//  DebugBattleLogCategory.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Categories for debug battle logging to control what information is displayed
///
/// Use a Set of these categories when initializing ConsoleDebugBattleLogger to
/// control which types of combat information are logged to console.
///
/// Example usage:
/// ```swift
/// let logger = ConsoleDebugBattleLogger(categories: [
///     .roundStart,
///     .dodgeCalculation,
///     .critCheck
/// ])
/// ```
public enum DebugBattleLogCategory: Sendable {
    /// Log round start information including hero stats, attack/defense selections
    case roundStart

    /// Log strength-based damage calculations
    case strengthDamage

    /// Log weapon-based damage calculations
    case weaponDamage

    /// Log dodge chance calculations with two-stage system details
    case dodgeCalculation

    /// Log critical hit calculations with three-stage system details
    case critCalculation

    /// Log individual body part combat calculations
    case bodyPartCalculation

    /// Log round end results with HP changes and status summary
    case roundEnd

    /// Log a snapshot of the round state: alive counts, per-combatant HP,
    /// duel pairs, waiting lists, and hero flags. Useful for diagnosing
    /// pairing / waiting transitions in N×M battles.
    case roundState
}

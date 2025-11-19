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

    /// Log strength damage calculations with distribution and weights
    case strengthDamage

    /// Log weapon damage calculations for left and right hands
    case weaponDamage

    /// Log dodge chance calculations with two-stage system details
    case dodgeCalculation

    /// Log critical hit chance calculations
    case critCheck

    /// Log individual body part combat calculations
    case bodyPartCalculation

    /// Log round end results with HP changes and status summary
    case roundEnd
}

//
//  NoOpDebugBattleLogger.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// No-operation implementation of DebugBattleLogger for production builds
///
/// All methods are empty, providing zero performance overhead.
/// Use this implementation in release/production builds to disable debug logging.
public final class NoOpDebugBattleLogger: DebugBattleLogger {

    public init() {}

    public func logRoundStart(
        roundNumber: Int,
        playerSnapshot: CombatantSnapshot,
        botSnapshot: CombatantSnapshot,
        playerAttack: [BodyPart],
        playerDefense: [BodyPart],
        botAttack: [BodyPart],
        botDefense: [BodyPart]
    ) {
        // No-op
    }

    public func logStrengthDamage(
        hero: String,
        strength: Int16,
        distribution: [Int16],
        weights: [Int],
        selectedValue: Int16
    ) {
        // No-op
    }

    public func logWeaponDamage(
        hero: String,
        hand: String,
        weaponName: String,
        minDamage: Int16,
        maxDamage: Int16,
        selectedValue: Int16
    ) {
        // No-op
    }

    public func logDodgeCalculation(
        defender: String,
        result: DodgeCalculationResult,
        agility: Int16,
        instinct: Int16
    ) {
        // No-op
    }

    public func logCritCalculation(
        attacker: String,
        result: CritCalculationResult,
        power: Int16,
        instinct: Int16
    ) {
        // No-op
    }

    public func logBodyPartCalculation(
        attacker: String,
        defender: String,
        bodyPart: BodyPart,
        isAttacked: Bool,
        isDefended: Bool,
        baseDamage: Int?,
        armor: Int?,
        finalDamage: Int?,
        finalStatus: PointStatus
    ) {
        // No-op
    }

    public func logRoundEnd(
        roundNumber: Int,
        playerOldHP: Int,
        playerNewHP: Int,
        botOldHP: Int,
        botNewHP: Int,
        playerResults: [BodyPart: PointStatus],
        botResults: [BodyPart: PointStatus]
    ) {
        // No-op
    }
}

// MARK: - Sendable Conformance
// Thread-safe: Stateless class with no stored properties. All methods are no-op.
extension NoOpDebugBattleLogger: @unchecked Sendable {}

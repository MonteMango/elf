//
//  NoOpDebugBattleLogger.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// No-op `DebugBattleLogger` used as the `testValue` for the `\.debugBattleLogger`
/// dependency — lets combat tests exercise calculators without mocking out
/// every logging callback or producing noisy console output.
public struct NoOpDebugBattleLogger: DebugBattleLogger {

    public init() {}

    public func logRoundStart(
        roundNumber: Int,
        playerSnapshot: CombatantSnapshot,
        botSnapshot: CombatantSnapshot,
        playerAttack: [BodyPart],
        playerDefense: [BodyPart],
        botAttack: [BodyPart],
        botDefense: [BodyPart]
    ) {}

    public func logDodgeCalculation(
        defender: String,
        result: DodgeCalculationResult,
        agility: Int16,
        instinct: Int16
    ) {}

    public func logCritCalculation(
        attacker: String,
        result: CritCalculationResult,
        power: Int16,
        instinct: Int16
    ) {}

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
    ) {}

    public func logRoundEnd(
        roundNumber: Int,
        playerOldHP: Int,
        playerNewHP: Int,
        botOldHP: Int,
        botNewHP: Int,
        playerResults: [BodyPart: PointStatus],
        botResults: [BodyPart: PointStatus]
    ) {}
}

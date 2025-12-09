//
//  ElfSnapshotCombatCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

public final class ElfSnapshotCombatCalculator: SnapshotCombatCalculator {

    private let damageService: DamageService
    private let dodgeService: DodgeService
    private let critService: CritService
    private let debugLogger: DebugBattleLogger

    public init(
        damageService: DamageService,
        dodgeService: DodgeService,
        critService: CritService,
        debugLogger: DebugBattleLogger
    ) {
        self.damageService = damageService
        self.dodgeService = dodgeService
        self.critService = critService
        self.debugLogger = debugLogger
    }

    public func calculatePointStatus(
        attackingPoints: Set<BodyPart>,
        defendingPoints: Set<BodyPart>,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot
    ) async -> [BodyPart: PointStatus] {
        var results: [BodyPart: PointStatus] = [:]
        let allBodyParts: [BodyPart] = [.head, .body, .leftHand, .rightHand, .legs]

        for bodyPart in allBodyParts {
            let isAttacked = attackingPoints.contains(bodyPart)
            let isDefended = defendingPoints.contains(bodyPart)

            if isAttacked && isDefended {
                // Case 1: Attack meets Defense - Check if crit breaks the block
                let critResult = critService.calculateCrit(
                    power: Int16(attacker.power),
                    instinct: Int16(defender.intuition),
                    defenderAgility: Int16(defender.agility)
                )

                debugLogger.logCritCalculation(
                    attacker: attacker.name,
                    result: critResult,
                    power: Int16(attacker.power),
                    instinct: Int16(defender.intuition)
                )

                if critResult.success {
                    // Crit breaks the block
                    let (strengthDamage, attackDamage, defenderArmor) = await calculateDamageComponents(
                        attacker: attacker,
                        defender: defender,
                        bodyPart: bodyPart
                    )

                    let finalStatus = PointStatus.critHit(
                        weaponDamage: attackDamage,
                        strengthDamage: strengthDamage,
                        defenderArmor: defenderArmor,
                        multiplier: critResult.selectedMultiplier
                    )
                    results[bodyPart] = finalStatus

                    logBodyPartResult(
                        attacker: attacker,
                        defender: defender,
                        bodyPart: bodyPart,
                        isAttacked: isAttacked,
                        isDefended: isDefended,
                        strengthDamage: strengthDamage,
                        attackDamage: attackDamage,
                        defenderArmor: defenderArmor,
                        multiplier: critResult.selectedMultiplier,
                        finalStatus: finalStatus
                    )
                } else {
                    // Block succeeded
                    let finalStatus = PointStatus.blocked(wasCrit: false)
                    results[bodyPart] = finalStatus

                    debugLogger.logBodyPartCalculation(
                        attacker: attacker.name,
                        defender: defender.name,
                        bodyPart: bodyPart,
                        isAttacked: isAttacked,
                        isDefended: isDefended,
                        baseDamage: nil,
                        armor: nil,
                        finalDamage: nil,
                        finalStatus: finalStatus
                    )
                }

            } else if isAttacked && !isDefended {
                // Case 2: Attack without Defense - Check dodge first, then crit
                let dodgeResult = dodgeService.calculateDodge(
                    agility: Int16(defender.agility),
                    instinct: Int16(attacker.intuition)
                )

                debugLogger.logDodgeCalculation(
                    defender: defender.name,
                    result: dodgeResult,
                    agility: Int16(defender.agility),
                    instinct: Int16(attacker.intuition)
                )

                if dodgeResult.success {
                    // Dodged
                    let critResult = critService.calculateCrit(
                        power: Int16(attacker.power),
                        instinct: Int16(defender.intuition),
                        defenderAgility: Int16(defender.agility)
                    )

                    let finalStatus = PointStatus.dodged(wasCrit: critResult.success)
                    results[bodyPart] = finalStatus

                    debugLogger.logBodyPartCalculation(
                        attacker: attacker.name,
                        defender: defender.name,
                        bodyPart: bodyPart,
                        isAttacked: isAttacked,
                        isDefended: isDefended,
                        baseDamage: nil,
                        armor: nil,
                        finalDamage: nil,
                        finalStatus: finalStatus
                    )
                } else {
                    // Not dodged - check for crit
                    let critResult = critService.calculateCrit(
                        power: Int16(attacker.power),
                        instinct: Int16(defender.intuition),
                        defenderAgility: Int16(defender.agility)
                    )

                    debugLogger.logCritCalculation(
                        attacker: attacker.name,
                        result: critResult,
                        power: Int16(attacker.power),
                        instinct: Int16(defender.intuition)
                    )

                    let (strengthDamage, attackDamage, defenderArmor) = await calculateDamageComponents(
                        attacker: attacker,
                        defender: defender,
                        bodyPart: bodyPart
                    )

                    if critResult.success {
                        // Critical hit
                        let finalStatus = PointStatus.critHit(
                            weaponDamage: attackDamage,
                            strengthDamage: strengthDamage,
                            defenderArmor: defenderArmor,
                            multiplier: critResult.selectedMultiplier
                        )
                        results[bodyPart] = finalStatus

                        logBodyPartResult(
                            attacker: attacker,
                            defender: defender,
                            bodyPart: bodyPart,
                            isAttacked: isAttacked,
                            isDefended: isDefended,
                            strengthDamage: strengthDamage,
                            attackDamage: attackDamage,
                            defenderArmor: defenderArmor,
                            multiplier: critResult.selectedMultiplier,
                            finalStatus: finalStatus
                        )
                    } else {
                        // Normal hit
                        let finalStatus = PointStatus.hit(
                            weaponDamage: attackDamage,
                            strengthDamage: strengthDamage,
                            defenderArmor: defenderArmor
                        )
                        results[bodyPart] = finalStatus

                        logBodyPartResult(
                            attacker: attacker,
                            defender: defender,
                            bodyPart: bodyPart,
                            isAttacked: isAttacked,
                            isDefended: isDefended,
                            strengthDamage: strengthDamage,
                            attackDamage: attackDamage,
                            defenderArmor: defenderArmor,
                            multiplier: nil,
                            finalStatus: finalStatus
                        )
                    }
                }

            } else {
                // Case 3: No attack on this body part
                let finalStatus = PointStatus.nothing
                results[bodyPart] = finalStatus

                debugLogger.logBodyPartCalculation(
                    attacker: attacker.name,
                    defender: defender.name,
                    bodyPart: bodyPart,
                    isAttacked: isAttacked,
                    isDefended: isDefended,
                    baseDamage: nil,
                    armor: nil,
                    finalDamage: nil,
                    finalStatus: finalStatus
                )
            }
        }

        return results
    }

    // MARK: - Private Helpers

    private func calculateDamageComponents(
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        bodyPart: BodyPart
    ) async -> (strengthDamage: Int, attackDamage: Int, defenderArmor: Int) {
        // Get strength-based damage
        let strengthDamage = await damageService.getRandomStrengthDamage(Int16(attacker.strength))

        // Get attack damage (weapon damage for elves, natural attack for monsters)
        let attackDamage: Int
        if attacker.maximumAttack > attacker.minimumAttack {
            attackDamage = Int.random(in: attacker.minimumAttack...attacker.maximumAttack)
        } else if attacker.maximumAttack == attacker.minimumAttack {
            attackDamage = attacker.minimumAttack
        } else {
            attackDamage = 0
        }

        // Get defender's armor for this body part
        let defenderArmor = defender.armorValues[bodyPart] ?? 0

        return (Int(strengthDamage), attackDamage, defenderArmor)
    }

    private func logBodyPartResult(
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        bodyPart: BodyPart,
        isAttacked: Bool,
        isDefended: Bool,
        strengthDamage: Int,
        attackDamage: Int,
        defenderArmor: Int,
        multiplier: Double?,
        finalStatus: PointStatus
    ) {
        let baseDamage = strengthDamage + attackDamage
        let finalDamage: Int

        if let mult = multiplier {
            finalDamage = max(0, Int(Double(baseDamage) * mult) - defenderArmor)
        } else {
            finalDamage = max(0, baseDamage - defenderArmor)
        }

        debugLogger.logBodyPartCalculation(
            attacker: attacker.name,
            defender: defender.name,
            bodyPart: bodyPart,
            isAttacked: isAttacked,
            isDefended: isDefended,
            baseDamage: baseDamage,
            armor: defenderArmor,
            finalDamage: finalDamage,
            finalStatus: finalStatus
        )
    }
}

// MARK: - Sendable Conformance
extension ElfSnapshotCombatCalculator: @unchecked Sendable {}

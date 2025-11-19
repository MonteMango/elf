//
//  BasicCombatCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public final class BasicCombatCalculator: CombatCalculator {

    private let damageService: DamageService
    private let dodgeService: DodgeService
    private let debugLogger: DebugBattleLogger

    public init(
        damageService: DamageService,
        dodgeService: DodgeService,
        debugLogger: DebugBattleLogger
    ) {
        self.damageService = damageService
        self.dodgeService = dodgeService
        self.debugLogger = debugLogger
    }

    public func calculatePointStatus(
        attackingPoints: Set<BodyPart>,
        defendingPoints: Set<BodyPart>,
        attacker: ElfHero,
        defender: ElfHero,
        attackerName: String = "Attacker",
        defenderName: String = "Defender"
    ) async -> [BodyPart: PointStatus] {
        var results: [BodyPart: PointStatus] = [:]
        let allBodyParts: [BodyPart] = [.head, .body, .leftHand, .rightHand, .legs]

        // Get attacker total strength for damage calculation
        let totalStrength = attacker.fightStyleAttributes.strength + attacker.randomLevelAttributes.strength

        for bodyPart in allBodyParts {
            let isAttacked = attackingPoints.contains(bodyPart)
            let isDefended = defendingPoints.contains(bodyPart)

            if isAttacked && isDefended {
                // Case 1: Attack meets Defense - Check if crit breaks the block
                let attackerPower = attacker.fightStyleAttributes.power + attacker.randomLevelAttributes.power
                let defenderInstinct = defender.fightStyleAttributes.instinct + defender.randomLevelAttributes.instinct
                let critChance = max(0, min(100, Int(attackerPower) - Int(defenderInstinct)))
                let critRoll = Int.random(in: 1...100)

                let isCrit = critRoll <= critChance
                let multiplier = isCrit ? 2.0 : 1.0

                // Log crit check
                debugLogger.logCritCheck(
                    attacker: attackerName,
                    power: attackerPower,
                    defenderInstinct: defenderInstinct,
                    critChance: critChance,
                    roll: critRoll,
                    isCrit: isCrit,
                    multiplier: multiplier
                )

                if isCrit {
                    // Crit breaks the block
                    let strengthDistribution = await damageService.getStrengthDamageDistribution(totalStrength)
                    let strengthDamage = await damageService.getRandomStrengthDamage(totalStrength)
                    let weaponDamage = await damageService.getRandomWeaponDamage(weaponId: attacker.rightHandWeaponElfItem?.id)

                    // Log strength damage
                    debugLogger.logStrengthDamage(
                        hero: attackerName,
                        strength: totalStrength,
                        distribution: strengthDistribution.distribution,
                        weights: strengthDistribution.weights,
                        selectedValue: strengthDamage
                    )

                    // Log weapon damage
                    if let weapon = attacker.rightHandWeaponElfItem {
                        let weaponDamageRange = await damageService.getWeaponDamage(weaponId: weapon.id) ?? (minDmg: 0, maxDmg: 0)
                        debugLogger.logWeaponDamage(
                            hero: attackerName,
                            hand: "right",
                            weaponName: weapon.item.title,
                            minDamage: weaponDamageRange.minDmg,
                            maxDamage: weaponDamageRange.maxDmg,
                            selectedValue: weaponDamage
                        )
                    }

                    let baseDamage = Int(strengthDamage + weaponDamage)
                    let defenderArmor = Int(defender.armorValues[bodyPart] ?? 0)
                    let finalDamage = max(0, Int(Double(baseDamage) * multiplier) - defenderArmor)

                    let finalStatus = PointStatus.critHit(damage: finalDamage)
                    results[bodyPart] = finalStatus

                    // Log body part calculation
                    debugLogger.logBodyPartCalculation(
                        attacker: attackerName,
                        defender: defenderName,
                        bodyPart: bodyPart,
                        isAttacked: isAttacked,
                        isDefended: isDefended,
                        baseDamage: baseDamage,
                        armor: defenderArmor,
                        finalDamage: finalDamage,
                        finalStatus: finalStatus
                    )
                } else {
                    // Block succeeded
                    let finalStatus = PointStatus.blocked
                    results[bodyPart] = finalStatus

                    // Log body part calculation
                    debugLogger.logBodyPartCalculation(
                        attacker: attackerName,
                        defender: defenderName,
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
                let defenderAgility = defender.fightStyleAttributes.agility + defender.randomLevelAttributes.agility
                let attackerInstinct = attacker.fightStyleAttributes.instinct + attacker.randomLevelAttributes.instinct

                // Use two-stage dodge calculation system
                let dodgeResult = dodgeService.calculateDodge(
                    agility: defenderAgility,
                    instinct: attackerInstinct
                )

                // Log dodge calculation
                debugLogger.logDodgeCalculation(
                    defender: defenderName,
                    result: dodgeResult,
                    agility: defenderAgility,
                    instinct: attackerInstinct
                )

                if dodgeResult.success {
                    // Dodged
                    let finalStatus = PointStatus.dodged
                    results[bodyPart] = finalStatus

                    // Log body part calculation
                    debugLogger.logBodyPartCalculation(
                        attacker: attackerName,
                        defender: defenderName,
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
                    let attackerPower = attacker.fightStyleAttributes.power + attacker.randomLevelAttributes.power
                    let defenderInstinct = defender.fightStyleAttributes.instinct + defender.randomLevelAttributes.instinct
                    let critChance = max(0, min(100, Int(attackerPower) - Int(defenderInstinct)))
                    let critRoll = Int.random(in: 1...100)

                    let isCrit = critRoll <= critChance
                    let multiplier = isCrit ? 1.5 : 1.0

                    // Log crit check
                    debugLogger.logCritCheck(
                        attacker: attackerName,
                        power: attackerPower,
                        defenderInstinct: defenderInstinct,
                        critChance: critChance,
                        roll: critRoll,
                        isCrit: isCrit,
                        multiplier: multiplier
                    )

                    let strengthDistribution = await damageService.getStrengthDamageDistribution(totalStrength)
                    let strengthDamage = await damageService.getRandomStrengthDamage(totalStrength)
                    let weaponDamage = await damageService.getRandomWeaponDamage(weaponId: attacker.rightHandWeaponElfItem?.id)

                    // Log strength damage
                    debugLogger.logStrengthDamage(
                        hero: attackerName,
                        strength: totalStrength,
                        distribution: strengthDistribution.distribution,
                        weights: strengthDistribution.weights,
                        selectedValue: strengthDamage
                    )

                    // Log weapon damage
                    if let weapon = attacker.rightHandWeaponElfItem {
                        let weaponDamageRange = await damageService.getWeaponDamage(weaponId: weapon.id) ?? (minDmg: 0, maxDmg: 0)
                        debugLogger.logWeaponDamage(
                            hero: attackerName,
                            hand: "right",
                            weaponName: weapon.item.title,
                            minDamage: weaponDamageRange.minDmg,
                            maxDamage: weaponDamageRange.maxDmg,
                            selectedValue: weaponDamage
                        )
                    }

                    let baseDamage = Int(strengthDamage + weaponDamage)
                    let defenderArmor = Int(defender.armorValues[bodyPart] ?? 0)

                    if isCrit {
                        // Critical hit
                        let finalDamage = max(0, Int(Double(baseDamage) * multiplier) - defenderArmor)
                        let finalStatus = PointStatus.critHit(damage: finalDamage)
                        results[bodyPart] = finalStatus

                        // Log body part calculation
                        debugLogger.logBodyPartCalculation(
                            attacker: attackerName,
                            defender: defenderName,
                            bodyPart: bodyPart,
                            isAttacked: isAttacked,
                            isDefended: isDefended,
                            baseDamage: baseDamage,
                            armor: defenderArmor,
                            finalDamage: finalDamage,
                            finalStatus: finalStatus
                        )
                    } else {
                        // Normal hit
                        let finalDamage = max(0, baseDamage - defenderArmor)
                        let finalStatus = PointStatus.hit(damage: finalDamage)
                        results[bodyPart] = finalStatus

                        // Log body part calculation
                        debugLogger.logBodyPartCalculation(
                            attacker: attackerName,
                            defender: defenderName,
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

            } else {
                let finalStatus = PointStatus.nothing
                results[bodyPart] = finalStatus

                // Log body part calculation
                debugLogger.logBodyPartCalculation(
                    attacker: attackerName,
                    defender: defenderName,
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
}

// MARK: - Sendable Conformance
extension BasicCombatCalculator: @unchecked Sendable {}

//
//  BasicCombatCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public final class BasicCombatCalculator: CombatCalculator {

    private let damageService: DamageService

    public init(damageService: DamageService) {
        self.damageService = damageService
    }

    public func calculatePointStatus(
        attackingPoints: Set<BodyPart>,
        defendingPoints: Set<BodyPart>,
        attacker: ElfHero,
        defender: ElfHero
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

                if critRoll <= critChance {
                    // Crit breaks the block
                    let strengthDamage = await damageService.getRandomStrengthDamage(totalStrength)
                    let weaponDamage = await damageService.getRandomWeaponDamage(weaponId: attacker.rightHandWeaponElfItem?.id)
                    let baseDamage = Double(strengthDamage + weaponDamage)
                    let defenderArmor = defender.armorValues[bodyPart] ?? 0
                    let finalDamage = max(0, Int(baseDamage * 2.0) - Int(defenderArmor))
                    results[bodyPart] = .critHit(damage: finalDamage)
                } else {
                    // Block succeeded
                    results[bodyPart] = .blocked
                }

            } else if isAttacked && !isDefended {
                // Case 2: Attack without Defense - Check dodge first, then crit
                let defenderAgility = defender.fightStyleAttributes.agility + defender.randomLevelAttributes.agility
                let attackerInstinct = attacker.fightStyleAttributes.instinct + attacker.randomLevelAttributes.instinct
                let dodgeChance = max(0, min(100, Int(defenderAgility) - Int(attackerInstinct)))
                let dodgeRoll = Int.random(in: 1...100)

                if dodgeRoll <= dodgeChance {
                    // Dodged
                    results[bodyPart] = .dodged
                } else {
                    // Not dodged - check for crit
                    let attackerPower = attacker.fightStyleAttributes.power + attacker.randomLevelAttributes.power
                    let defenderInstinct = defender.fightStyleAttributes.instinct + defender.randomLevelAttributes.instinct
                    let critChance = max(0, min(100, Int(attackerPower) - Int(defenderInstinct)))
                    let critRoll = Int.random(in: 1...100)

                    let strengthDamage = await damageService.getRandomStrengthDamage(totalStrength)
                    let weaponDamage = await damageService.getRandomWeaponDamage(weaponId: attacker.rightHandWeaponElfItem?.id)
                    let baseDamage = strengthDamage + weaponDamage
                    let defenderArmor = defender.armorValues[bodyPart] ?? 0

                    if critRoll <= critChance {
                        // Critical hit
                        let finalDamage = max(0, Int(Double(baseDamage) * 1.5) - Int(defenderArmor))
                        results[bodyPart] = .critHit(damage: finalDamage)
                    } else {
                        // Normal hit
                        let finalDamage = max(0, Int(baseDamage) - Int(defenderArmor))
                        results[bodyPart] = .hit(damage: finalDamage)
                    }
                }

            } else {
                results[bodyPart] = .nothing
            }
        }

        return results
    }
}

// MARK: - Sendable Conformance
extension BasicCombatCalculator: @unchecked Sendable {}

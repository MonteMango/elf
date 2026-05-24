//
//  ElfSnapshotCombatCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Dependencies
import Foundation

public final class ElfSnapshotCombatCalculator: SnapshotCombatCalculator {

    private let damageService: any DamageService
    private let dodgeService: any DodgeService
    private let critService: any CritService
    private let enduranceService: any EnduranceService
    private let debugLogger: any DebugBattleLogger

    public init() {
        @Dependency(\.damageService) var damageService
        @Dependency(\.dodgeService) var dodgeService
        @Dependency(\.critService) var critService
        @Dependency(\.enduranceService) var enduranceService
        @Dependency(\.debugBattleLogger) var debugLogger
        self.damageService = damageService
        self.dodgeService = dodgeService
        self.critService = critService
        self.enduranceService = enduranceService
        self.debugLogger = debugLogger
    }

    public func calculatePointStatus(
        attackingPoints: Set<BodyPart>,
        defendingPoints: Set<BodyPart>,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot
    ) -> [BodyPart: PointStatus] {
        var results: [BodyPart: PointStatus] = [:]
        let allBodyParts: [BodyPart] = [.head, .body, .leftHand, .rightHand, .legs]

        // Strike-to-body-part mapping: among the attacker's chosen body parts,
        // the i-th in `allBodyParts` enum order is hit by strike i.
        // Strike 0 = primary (right-hand) weapon, strike 1 = off-hand (left)
        // for dual-wield. We iterate strikes in this order so the right
        // weapon's EP draw happens before the left weapon's — matches the
        // design rule "primary checks first, then secondary".
        let orderedAttackedBodyParts = allBodyParts.filter(attackingPoints.contains)

        // Body parts NOT attacked emit `.nothing` directly. Done in a
        // separate pass so the strike loop reads as pure per-strike logic.
        for bodyPart in allBodyParts where !attackingPoints.contains(bodyPart) {
            let finalStatus = PointStatus.nothing
            results[bodyPart] = finalStatus
            debugLogger.logBodyPartCalculation(
                attacker: attacker.name,
                defender: defender.name,
                bodyPart: bodyPart,
                isAttacked: false,
                isDefended: defendingPoints.contains(bodyPart),
                baseDamage: nil,
                armor: nil,
                finalDamage: nil,
                finalStatus: finalStatus
            )
        }

        // Drain EP sequentially across strikes in weapon order.
        var defenderRemainingEP = defender.currentEP

        for (strikeIndex, bodyPart) in orderedAttackedBodyParts.enumerated() {
            // Defensive: if attacker selected more body parts than there are
            // strikes (shouldn't happen — bot AI uses `attackPoints` as count),
            // fall back to the last strike's profile.
            let profile = attacker.attacks[min(strikeIndex, max(0, attacker.attacks.count - 1))]

            // Per-strike block cost. Endurance is constant across the round,
            // but base cost varies by weapon, so we recompute per strike.
            let blockCost = enduranceService.calculateBlockCost(
                baseCost: profile.epBlockCost,
                defenderEndurance: defender.endurance
            )

            let isDefended = defendingPoints.contains(bodyPart)
            if isDefended {
                results[bodyPart] = resolveDefendedAttack(
                    bodyPart: bodyPart,
                    profile: profile,
                    blockCost: blockCost,
                    defenderRemainingEP: &defenderRemainingEP,
                    attacker: attacker,
                    defender: defender
                )
            } else {
                results[bodyPart] = resolveUndefendedAttack(
                    bodyPart: bodyPart,
                    isAttacked: true,
                    isDefended: false,
                    profile: profile,
                    attacker: attacker,
                    defender: defender
                )
            }
        }

        return results
    }

    // MARK: - Private Helpers

    /// Resolves a body part that was both attacked and defended for one strike.
    /// Mutates `defenderRemainingEP` in place when the block is paid for.
    private func resolveDefendedAttack(
        bodyPart: BodyPart,
        profile: AttackProfile,
        blockCost: Int,
        defenderRemainingEP: inout Int,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot
    ) -> PointStatus {
        // Insufficient EP → block input is accepted but provides no
        // protection. Resolve as if the part were not blocked.
        guard blockCost > 0 && defenderRemainingEP >= blockCost else {
            return resolveUndefendedAttack(
                bodyPart: bodyPart,
                isAttacked: true,
                isDefended: true,
                profile: profile,
                attacker: attacker,
                defender: defender
            )
        }

        // EP is committed up-front. A block that catches a crit reduces the
        // crit multiplier to 1.0× (normal hit damage), but EP is still spent
        // — the defender pays for the protection that downgraded the crit.
        defenderRemainingEP -= blockCost

        let critResult = critService.calculateCrit(
            power: Int16(attacker.power),
            instinct: Int16(defender.intuition)
        )

        debugLogger.logCritCalculation(
            attacker: attacker.name,
            result: critResult,
            power: Int16(attacker.power),
            instinct: Int16(defender.intuition)
        )

        if critResult.success {
            let (strengthDamage, attackDamage, defenderArmor) = calculateDamageComponents(
                profile: profile,
                attacker: attacker,
                defender: defender,
                bodyPart: bodyPart
            )

            // Crit succeeded against a blocked part: damage is scaled by
            // `blockedCritMultiplier` (default `1.0` = normal-hit damage)
            // instead of the rolled multiplier. The `PointStatus.critHit`
            // case is kept so UI still renders the crit indicator and
            // statistics still record it as a crit success — only the
            // damage scaling is suppressed.
            let blockedCritMultiplier = GameMechanicsConstants.blockedCritMultiplier
            let finalStatus = PointStatus.critHit(
                weaponDamage: attackDamage,
                strengthDamage: strengthDamage,
                defenderArmor: defenderArmor,
                multiplier: blockedCritMultiplier,
                epSpent: blockCost
            )

            logBodyPartResult(
                attacker: attacker,
                defender: defender,
                bodyPart: bodyPart,
                isAttacked: true,
                isDefended: true,
                strengthDamage: strengthDamage,
                attackDamage: attackDamage,
                defenderArmor: defenderArmor,
                multiplier: blockedCritMultiplier,
                finalStatus: finalStatus
            )
            return finalStatus
        }

        let finalStatus = PointStatus.blocked(wasCrit: false, epSpent: blockCost)
        debugLogger.logBodyPartCalculation(
            attacker: attacker.name,
            defender: defender.name,
            bodyPart: bodyPart,
            isAttacked: true,
            isDefended: true,
            baseDamage: nil,
            armor: nil,
            finalDamage: nil,
            finalStatus: finalStatus
        )
        return finalStatus
    }

    private func resolveUndefendedAttack(
        bodyPart: BodyPart,
        isAttacked: Bool,
        isDefended: Bool,
        profile: AttackProfile,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot
    ) -> PointStatus {
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
            let critResult = critService.calculateCrit(
                power: Int16(attacker.power),
                instinct: Int16(defender.intuition)
            )

            let finalStatus = PointStatus.dodged(wasCrit: critResult.success)

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
            return finalStatus
        }

        let critResult = critService.calculateCrit(
            power: Int16(attacker.power),
            instinct: Int16(defender.intuition)
        )

        debugLogger.logCritCalculation(
            attacker: attacker.name,
            result: critResult,
            power: Int16(attacker.power),
            instinct: Int16(defender.intuition)
        )

        let (strengthDamage, attackDamage, defenderArmor) = calculateDamageComponents(
            profile: profile,
            attacker: attacker,
            defender: defender,
            bodyPart: bodyPart
        )

        if critResult.success {
            let finalStatus = PointStatus.critHit(
                weaponDamage: attackDamage,
                strengthDamage: strengthDamage,
                defenderArmor: defenderArmor,
                multiplier: critResult.selectedMultiplier,
                epSpent: 0
            )

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
            return finalStatus
        }

        let finalStatus = PointStatus.hit(
            weaponDamage: attackDamage,
            strengthDamage: strengthDamage,
            defenderArmor: defenderArmor
        )

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
        return finalStatus
    }

    private func calculateDamageComponents(
        profile: AttackProfile,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        bodyPart: BodyPart
    ) -> (strengthDamage: Int, attackDamage: Int, defenderArmor: Int) {
        // Get strength-based damage
        let strengthDamage = damageService.getRandomStrengthDamage(Int16(attacker.strength))

        // Per-strike weapon damage from this strike's profile.
        let attackDamage: Int
        if profile.maximumAttack > profile.minimumAttack {
            attackDamage = Int.random(in: profile.minimumAttack...profile.maximumAttack)
        } else if profile.maximumAttack == profile.minimumAttack {
            attackDamage = profile.minimumAttack
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

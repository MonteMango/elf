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
    private let buffEffectsCalculator: any BuffEffectsCalculator
    private let debugLogger: any DebugBattleLogger

    public init() {
        @Dependency(\.damageService) var damageService
        @Dependency(\.dodgeService) var dodgeService
        @Dependency(\.critService) var critService
        @Dependency(\.enduranceService) var enduranceService
        @Dependency(\.buffEffectsCalculator) var buffEffectsCalculator
        @Dependency(\.debugBattleLogger) var debugLogger
        self.damageService = damageService
        self.dodgeService = dodgeService
        self.critService = critService
        self.enduranceService = enduranceService
        self.buffEffectsCalculator = buffEffectsCalculator
        self.debugLogger = debugLogger
    }

    public func calculatePointStatus(
        attackingPoints: Set<BodyPart>,
        defendingPoints: Set<BodyPart>,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot
    ) -> [BodyPart: PointStatus] {
        let attackerEff = buffEffectsCalculator.effectiveAttributes(of: attacker)
        let defenderEff = buffEffectsCalculator.effectiveAttributes(of: defender)

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
                defenderEndurance: Int(defenderEff.endurance.value)
            )

            let isDefended = defendingPoints.contains(bodyPart)
            if isDefended {
                results[bodyPart] = resolveDefendedAttack(
                    bodyPart: bodyPart,
                    profile: profile,
                    blockCost: blockCost,
                    defenderRemainingEP: &defenderRemainingEP,
                    attacker: attacker,
                    defender: defender,
                    attackerEff: attackerEff,
                    defenderEff: defenderEff
                )
            } else {
                results[bodyPart] = resolveUndefendedAttack(
                    bodyPart: bodyPart,
                    isAttacked: true,
                    isDefended: false,
                    profile: profile,
                    attacker: attacker,
                    defender: defender,
                    attackerEff: attackerEff,
                    defenderEff: defenderEff
                )
            }
        }

        return results
    }

    // MARK: - Private Helpers

    /// Resolves a body part that was both attacked and defended for one strike.
    /// Mutates `defenderRemainingEP` in place when EP is paid for the block.
    ///
    /// Branching rules (defender's EP vs the strike's `blockCost`):
    ///   - `blockCost <= 0`         → fall through to undefended (treated as
    ///     a free strike — current behavior).
    ///   - `EP >= blockCost`        → full block; pay `blockCost`.
    ///   - `0 < EP < blockCost`     → full block; pay the remainder, EP → 0.
    ///     The defender will be `Exhausted` at end of round (runner hook).
    ///   - `EP == 0` + Exhausted    → weak block; pay no EP, take half the
    ///     would-be damage (`exhaustedBlockDamageMultiplier`).
    ///   - `EP == 0` + no Exhausted → fall through to undefended (defender
    ///     has no resource to put a guard up).
    private func resolveDefendedAttack(
        bodyPart: BodyPart,
        profile: AttackProfile,
        blockCost: Int,
        defenderRemainingEP: inout Int,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        attackerEff: HeroAttributes,
        defenderEff: HeroAttributes
    ) -> PointStatus {
        if blockCost <= 0 {
            return resolveUndefendedAttack(
                bodyPart: bodyPart, isAttacked: true, isDefended: true,
                profile: profile, attacker: attacker, defender: defender,
                attackerEff: attackerEff, defenderEff: defenderEff
            )
        }

        if defenderRemainingEP >= blockCost {
            defenderRemainingEP -= blockCost
            return resolveSuccessfulBlock(
                bodyPart: bodyPart, profile: profile, spentEP: blockCost,
                attacker: attacker, defender: defender,
                attackerEff: attackerEff, defenderEff: defenderEff
            )
        }

        if defenderRemainingEP > 0 {
            // Drain whatever EP is left — the block still lands at full
            // effectiveness; the defender will be `Exhausted` next round.
            let spent = defenderRemainingEP
            defenderRemainingEP = 0
            return resolveSuccessfulBlock(
                bodyPart: bodyPart, profile: profile, spentEP: spent,
                attacker: attacker, defender: defender,
                attackerEff: attackerEff, defenderEff: defenderEff
            )
        }

        // EP == 0 here. Exhausted defenders still get a guard up at half
        // effectiveness; non-Exhausted have nothing left to spend.
        let isExhausted = defender.battleBuffs.contains { $0.buffId == BuffCatalogID.exhaustedBattle }
        if isExhausted {
            return resolveWeakBlock(
                bodyPart: bodyPart, profile: profile,
                attacker: attacker, defender: defender,
                attackerEff: attackerEff, defenderEff: defenderEff
            )
        }

        return resolveUndefendedAttack(
            bodyPart: bodyPart, isAttacked: true, isDefended: true,
            profile: profile, attacker: attacker, defender: defender,
            attackerEff: attackerEff, defenderEff: defenderEff
        )
    }

    /// Successful-block resolution: rolls the crit check, scales a crit
    /// hit by a multiplier rolled from `blockedCritMultiplierWeights` (so
    /// the crit still shows up in stats but its damage scaling sits in a
    /// downgraded distribution — most often 1.0×–1.25×, never 2.0×+), and
    /// otherwise returns a clean `.blocked`. EP has already been committed
    /// by the caller.
    private func resolveSuccessfulBlock(
        bodyPart: BodyPart,
        profile: AttackProfile,
        spentEP: Int,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        attackerEff: HeroAttributes,
        defenderEff: HeroAttributes
    ) -> PointStatus {
        let critResult = critService.calculateCrit(
            power: attackerEff.power.value,
            instinct: defenderEff.instinct.value
        )

        debugLogger.logCritCalculation(
            attacker: attacker.name,
            result: critResult,
            power: attackerEff.power.value,
            instinct: defenderEff.instinct.value
        )

        if critResult.success {
            let (strengthDamage, attackDamage, enduranceReduction, defenderArmor) = calculateDamageComponents(
                profile: profile,
                attackerEff: attackerEff,
                defenderEff: defenderEff,
                defender: defender,
                bodyPart: bodyPart
            )

            let blockedMultiplier = critService.selectBlockedCritMultiplier()
            let finalStatus = PointStatus.critHit(
                weaponDamage: attackDamage,
                strengthDamage: strengthDamage,
                enduranceReduction: enduranceReduction,
                defenderArmor: defenderArmor,
                multiplier: blockedMultiplier,
                epSpent: spentEP
            )

            logBodyPartResult(
                attacker: attacker, defender: defender, bodyPart: bodyPart,
                isAttacked: true, isDefended: true,
                strengthDamage: strengthDamage, attackDamage: attackDamage,
                enduranceReduction: enduranceReduction, defenderArmor: defenderArmor,
                multiplier: blockedMultiplier, finalStatus: finalStatus
            )
            return finalStatus
        }

        let finalStatus = PointStatus.blocked(wasCrit: false, epSpent: spentEP)
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

    /// Weak-block path: Exhausted defender at 0 EP. No dodge roll (the
    /// defender chose to block), no EP cost (none to spend).
    ///
    /// Asymmetric crit handling — by design:
    ///   - No crit → full damage chain × `exhaustedBlockDamageMultiplier`
    ///     (defender takes a fraction of post-armor damage).
    ///   - Crit succeeded → use `selectBlockedCritMultiplier()` so the crit
    ///     scaling is downgraded, but DO NOT also apply
    ///     `exhaustedBlockDamageMultiplier`. The downgraded multiplier is
    ///     the entire penalty against the attacker on this path; stacking
    ///     the halver on top would double-dip.
    /// Pre-reduction components are preserved on `PointStatus.weakBlocked`
    /// for logs/stats; `multiplier` is the value actually applied (rolled
    /// blocked-crit multiplier, or `1.0` for no-crit).
    private func resolveWeakBlock(
        bodyPart: BodyPart,
        profile: AttackProfile,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        attackerEff: HeroAttributes,
        defenderEff: HeroAttributes
    ) -> PointStatus {
        let critResult = critService.calculateCrit(
            power: attackerEff.power.value,
            instinct: defenderEff.instinct.value
        )

        debugLogger.logCritCalculation(
            attacker: attacker.name,
            result: critResult,
            power: attackerEff.power.value,
            instinct: defenderEff.instinct.value
        )

        let (strengthDamage, attackDamage, enduranceReduction, defenderArmor) = calculateDamageComponents(
            profile: profile,
            attackerEff: attackerEff,
            defenderEff: defenderEff,
            defender: defender,
            bodyPart: bodyPart
        )

        let finalDamage: Int
        let appliedMultiplier: Double

        if critResult.success {
            appliedMultiplier = critService.selectBlockedCritMultiplier()
            let amplifiedWeapon = Int(Double(attackDamage) * appliedMultiplier)
            finalDamage = max(0, amplifiedWeapon + strengthDamage - enduranceReduction - defenderArmor)
        } else {
            appliedMultiplier = 1.0
            let postArmorDamage = max(0, attackDamage + strengthDamage - enduranceReduction - defenderArmor)
            let halved = Double(postArmorDamage) * GameMechanicsConstants.exhaustedBlockDamageMultiplier
            finalDamage = Int(halved.rounded(.down))
        }

        let finalStatus = PointStatus.weakBlocked(
            weaponDamage: attackDamage,
            strengthDamage: strengthDamage,
            enduranceReduction: enduranceReduction,
            defenderArmor: defenderArmor,
            multiplier: appliedMultiplier,
            finalDamage: finalDamage,
            wasCrit: critResult.success
        )

        debugLogger.logBodyPartCalculation(
            attacker: attacker.name,
            defender: defender.name,
            bodyPart: bodyPart,
            isAttacked: true,
            isDefended: true,
            baseDamage: finalDamage,
            armor: defenderArmor,
            finalDamage: finalDamage,
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
        defender: CombatantSnapshot,
        attackerEff: HeroAttributes,
        defenderEff: HeroAttributes
    ) -> PointStatus {
        let dodgeResult = dodgeService.calculateDodge(
            agility: defenderEff.agility.value,
            instinct: attackerEff.instinct.value
        )

        debugLogger.logDodgeCalculation(
            defender: defender.name,
            result: dodgeResult,
            agility: defenderEff.agility.value,
            instinct: attackerEff.instinct.value
        )

        if dodgeResult.success {
            let critResult = critService.calculateCrit(
                power: attackerEff.power.value,
                instinct: defenderEff.instinct.value
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
            power: attackerEff.power.value,
            instinct: defenderEff.instinct.value
        )

        debugLogger.logCritCalculation(
            attacker: attacker.name,
            result: critResult,
            power: attackerEff.power.value,
            instinct: defenderEff.instinct.value
        )

        let (strengthDamage, attackDamage, enduranceReduction, defenderArmor) = calculateDamageComponents(
            profile: profile,
            attackerEff: attackerEff,
            defenderEff: defenderEff,
            defender: defender,
            bodyPart: bodyPart
        )

        if critResult.success {
            let finalStatus = PointStatus.critHit(
                weaponDamage: attackDamage,
                strengthDamage: strengthDamage,
                enduranceReduction: enduranceReduction,
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
                enduranceReduction: enduranceReduction,
                defenderArmor: defenderArmor,
                multiplier: critResult.selectedMultiplier,
                finalStatus: finalStatus
            )
            return finalStatus
        }

        let finalStatus = PointStatus.hit(
            weaponDamage: attackDamage,
            strengthDamage: strengthDamage,
            enduranceReduction: enduranceReduction,
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
            enduranceReduction: enduranceReduction,
            defenderArmor: defenderArmor,
            multiplier: nil,
            finalStatus: finalStatus
        )
        return finalStatus
    }

    private func calculateDamageComponents(
        profile: AttackProfile,
        attackerEff: HeroAttributes,
        defenderEff: HeroAttributes,
        defender: CombatantSnapshot,
        bodyPart: BodyPart
    ) -> (strengthDamage: Int, attackDamage: Int, enduranceReduction: Int, defenderArmor: Int) {
        // Get strength-based damage
        let strengthDamage = damageService.getRandomStrengthDamage(attackerEff.strength.value)

        // Per-strike weapon damage from this strike's profile.
        let attackDamage: Int
        if profile.maximumAttack > profile.minimumAttack {
            attackDamage = Int.random(in: profile.minimumAttack...profile.maximumAttack)
        } else if profile.maximumAttack == profile.minimumAttack {
            attackDamage = profile.minimumAttack
        } else {
            attackDamage = 0
        }

        // Defender's effective Endurance reduces incoming damage —
        // defensive mirror of Strength.
        let enduranceReduction = damageService.getRandomEnduranceDamageReduction(defenderEff.endurance.value)

        // Get defender's armor for this body part
        let defenderArmor = defender.armorValues[bodyPart] ?? 0

        return (Int(strengthDamage), attackDamage, Int(enduranceReduction), defenderArmor)
    }

    private func logBodyPartResult(
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        bodyPart: BodyPart,
        isAttacked: Bool,
        isDefended: Bool,
        strengthDamage: Int,
        attackDamage: Int,
        enduranceReduction: Int,
        defenderArmor: Int,
        multiplier: Double?,
        finalStatus: PointStatus
    ) {
        // Mirror the production damage formula: only the weapon swing scales
        // with the crit multiplier; Strength / Endurance / Armor are flat.
        let baseDamage: Int
        let finalDamage: Int

        if let mult = multiplier {
            let amplifiedWeapon = Int(Double(attackDamage) * mult)
            baseDamage = amplifiedWeapon + strengthDamage - enduranceReduction
            finalDamage = max(0, baseDamage - defenderArmor)
        } else {
            baseDamage = attackDamage + strengthDamage - enduranceReduction
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

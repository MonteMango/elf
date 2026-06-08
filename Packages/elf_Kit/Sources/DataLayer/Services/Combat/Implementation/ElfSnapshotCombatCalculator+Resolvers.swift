//
//  ElfSnapshotCombatCalculator+Resolvers.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Strike-resolution helpers for `ElfSnapshotCombatCalculator`. Kept in a
/// separate file so the primary type stays under SwiftLint's `type_body_length`
/// limit; methods are `internal` so they can reach the calculator's `let`
/// service properties from this extension.
extension ElfSnapshotCombatCalculator {

    /// Resolves a body part that was both attacked and defended for one
    /// strike, after the dodge roll already failed upstream in
    /// `calculatePointStatus`. Mutates `defenderRemainingEP` in place when
    /// EP is paid for the block.
    ///
    /// **Crit-amplified cost.** When the crit roll succeeds, a crit tax of
    /// `baseCost × (mult − 1) × critEPCostBonusRatio` EP is added on top of
    /// the normal block cost — a powerful crit is harder to parry, costs
    /// more EP. Computed BEFORE EP affordability is checked.
    ///
    /// Branching rules (defender's EP vs the strike's `actualBlockCost`):
    ///   - `baseBlockCost <= 0`     → fall through to a clean hit.
    ///   - `EP == 0` + Exhausted    → weak block; pay no EP, no cost amp.
    ///   - `EP == 0` + no Exhausted → fall through to a clean hit.
    ///   - `EP >= actualBlockCost`  → full block; pay `actualBlockCost`.
    ///   - `0 < EP < actualBlockCost` → block still holds; pay remainder,
    ///     EP → 0, Exhausted at end of round.
    internal func resolveDefendedAttack(
        bodyPart: BodyPart,
        profile: AttackProfile,
        blockCost: Int,
        defenderRemainingEP: inout Int,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        attackerEff: HeroAttributes,
        defenderEff: HeroAttributes,
        using generator: WithRandomNumberGenerator
    ) -> PointStatus {
        if blockCost <= 0 {
            return resolveHit(
                bodyPart: bodyPart, isDefended: true,
                profile: profile, attacker: attacker, defender: defender,
                attackerEff: attackerEff, defenderEff: defenderEff,
                using: generator
            )
        }

        // EP-exhausted special cases handled before crit roll (no point
        // rolling crit if defender already has no EP — the weak-block path
        // does its own crit roll, and the fall-through to resolveHit also
        // does its own).
        if defenderRemainingEP == 0 {
            if defender.isExhausted {
                return resolveWeakBlock(
                    bodyPart: bodyPart, profile: profile,
                    attacker: attacker, defender: defender,
                    attackerEff: attackerEff, defenderEff: defenderEff,
                    using: generator
                )
            }
            return resolveHit(
                bodyPart: bodyPart, isDefended: true,
                profile: profile, attacker: attacker, defender: defender,
                attackerEff: attackerEff, defenderEff: defenderEff,
                using: generator
            )
        }

        // Defender has EP — roll crit upfront so we can amplify the block
        // cost when a crit lands. Reusing the same result for damage avoids
        // a second roll inside resolveSuccessfulBlock.
        let critResult = rollAndLogCrit(
            attacker: attacker, attackerEff: attackerEff, defenderEff: defenderEff, using: generator
        )

        let actualBlockCost: Int
        if critResult.success {
            // Crit tax: a crit adds `base × bonus` EP on top of the normal
            // (endurance- and strength-adjusted) block cost. Equivalent to
            // the "flat reduction" model (amplified base minus the flat
            // endurance saving): the defender's flat EP saving from
            // Endurance doesn't scale with the amplification, so the
            // mechanic bites high-Endurance defenders — and a
            // strength-pressured cost above base isn't accidentally
            // discounted.
            let bonus = (critResult.selectedMultiplier - 1.0) * GameMechanicsConstants.critEPCostBonusRatio
            let critEPTax = Int((Double(profile.epBlockCost) * bonus).rounded())
            actualBlockCost = max(1, blockCost + critEPTax)
        } else {
            actualBlockCost = blockCost
        }

        let spent: Int
        if defenderRemainingEP >= actualBlockCost {
            spent = actualBlockCost
            defenderRemainingEP -= spent
        } else {
            // Drain whatever EP is left — the block still lands at full
            // effectiveness; the defender will be `Exhausted` next round.
            spent = defenderRemainingEP
            defenderRemainingEP = 0
        }

        return resolveSuccessfulBlock(
            bodyPart: bodyPart, profile: profile, spentEP: spent,
            precomputedCritResult: critResult,
            attacker: attacker, defender: defender,
            attackerEff: attackerEff, defenderEff: defenderEff,
            using: generator
        )
    }

    /// Successful-block resolution. Crit lands at full multiplier on blocked
    /// attacks (Session 2 design — the EP-amp tax already differentiates
    /// blocked from unblocked crits at the resource layer).
    internal func resolveSuccessfulBlock(
        bodyPart: BodyPart,
        profile: AttackProfile,
        spentEP: Int,
        precomputedCritResult: CritCalculationResult,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        attackerEff: HeroAttributes,
        defenderEff: HeroAttributes,
        using generator: WithRandomNumberGenerator
    ) -> PointStatus {
        let critResult = precomputedCritResult

        if critResult.success {
            let (strengthDamage, attackDamage, enduranceReduction, defenderArmor) = calculateDamageComponents(
                profile: profile,
                attackerEff: attackerEff,
                defenderEff: defenderEff,
                defender: defender,
                bodyPart: bodyPart,
                using: generator
            )
            let finalStatus = PointStatus.critHit(
                weaponDamage: attackDamage,
                strengthDamage: strengthDamage,
                enduranceReduction: enduranceReduction,
                defenderArmor: defenderArmor,
                multiplier: critResult.selectedMultiplier,
                epSpent: spentEP
            )
            logBodyPartResult(
                attacker: attacker, defender: defender, bodyPart: bodyPart,
                isAttacked: true, isDefended: true,
                strengthDamage: strengthDamage, attackDamage: attackDamage,
                enduranceReduction: enduranceReduction, defenderArmor: defenderArmor,
                multiplier: critResult.selectedMultiplier, finalStatus: finalStatus
            )
            return finalStatus
        }

        let finalStatus = PointStatus.blocked(epSpent: spentEP)
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

    /// Weak-block path: Exhausted defender at 0 EP. Dodge already failed
    /// upstream, no EP cost (none to spend).
    /// - Crit succeeded → full crit multiplier (Exhausted offers no
    ///   block-downgrade; `exhaustedBlockDamageMultiplier` NOT applied
    ///   on the crit branch — no double-dip).
    /// - No crit → post-armor damage × `exhaustedBlockDamageMultiplier`.
    internal func resolveWeakBlock(
        bodyPart: BodyPart,
        profile: AttackProfile,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        attackerEff: HeroAttributes,
        defenderEff: HeroAttributes,
        using generator: WithRandomNumberGenerator
    ) -> PointStatus {
        let critResult = rollAndLogCrit(
            attacker: attacker, attackerEff: attackerEff, defenderEff: defenderEff, using: generator
        )
        let (strengthDamage, attackDamage, enduranceReduction, defenderArmor) = calculateDamageComponents(
            profile: profile,
            attackerEff: attackerEff, defenderEff: defenderEff,
            defender: defender, bodyPart: bodyPart,
            using: generator
        )

        let finalDamage: Int
        let appliedMultiplier: Double
        if critResult.success {
            appliedMultiplier = critResult.selectedMultiplier
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
            attacker: attacker.name, defender: defender.name, bodyPart: bodyPart,
            isAttacked: true, isDefended: true,
            baseDamage: finalDamage, armor: defenderArmor,
            finalDamage: finalDamage, finalStatus: finalStatus
        )
        return finalStatus
    }

    /// Resolves a body part where dodge already failed (or wasn't attempted)
    /// and the attack proceeds without a successful block.
    internal func resolveHit(
        bodyPart: BodyPart,
        isDefended: Bool,
        profile: AttackProfile,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        attackerEff: HeroAttributes,
        defenderEff: HeroAttributes,
        using generator: WithRandomNumberGenerator
    ) -> PointStatus {
        let critResult = rollAndLogCrit(
            attacker: attacker, attackerEff: attackerEff, defenderEff: defenderEff, using: generator
        )
        let (strengthDamage, attackDamage, enduranceReduction, defenderArmor) = calculateDamageComponents(
            profile: profile,
            attackerEff: attackerEff, defenderEff: defenderEff,
            defender: defender, bodyPart: bodyPart,
            using: generator
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
                attacker: attacker, defender: defender, bodyPart: bodyPart,
                isAttacked: true, isDefended: isDefended,
                strengthDamage: strengthDamage, attackDamage: attackDamage,
                enduranceReduction: enduranceReduction, defenderArmor: defenderArmor,
                multiplier: critResult.selectedMultiplier, finalStatus: finalStatus
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
            attacker: attacker, defender: defender, bodyPart: bodyPart,
            isAttacked: true, isDefended: isDefended,
            strengthDamage: strengthDamage, attackDamage: attackDamage,
            enduranceReduction: enduranceReduction, defenderArmor: defenderArmor,
            multiplier: nil, finalStatus: finalStatus
        )
        return finalStatus
    }

    /// Rolls a crit and logs it — the shared preamble of
    /// `resolveDefendedAttack`, `resolveWeakBlock`, and `resolveHit`.
    /// (`resolveDodgedAttack` rolls without logging, by design.)
    internal func rollAndLogCrit(
        attacker: CombatantSnapshot,
        attackerEff: HeroAttributes,
        defenderEff: HeroAttributes,
        using generator: WithRandomNumberGenerator
    ) -> CritCalculationResult {
        let critResult = critService.calculateCrit(
            power: attackerEff.power.value,
            instinct: defenderEff.instinct.value,
            attackerLevel: attacker.level,
            using: generator
        )
        debugLogger.logCritCalculation(
            attacker: attacker.name, result: critResult,
            power: attackerEff.power.value, instinct: defenderEff.instinct.value
        )
        return critResult
    }

    /// Per-strike damage components.
    /// - Strength damage: attacker's raw STR alone (intuition no longer
    ///   contributes to offensive damage).
    /// - Reduction: two sqrt-curve rolls summed — INT @ 20 % of strength,
    ///   END @ 30 % of strength.
    /// - Weapon damage: rolled from this strike's `AttackProfile` range.
    internal func calculateDamageComponents(
        profile: AttackProfile,
        attackerEff: HeroAttributes,
        defenderEff: HeroAttributes,
        defender: CombatantSnapshot,
        bodyPart: BodyPart,
        using generator: WithRandomNumberGenerator
    ) -> (strengthDamage: Int, attackDamage: Int, enduranceReduction: Int, defenderArmor: Int) {
        let strengthDamage = damageService.getRandomStrengthDamage(attackerEff.strength.value, using: generator)

        let attackDamage: Int
        if profile.maximumAttack > profile.minimumAttack {
            attackDamage = generator { rng in
                Int.random(in: profile.minimumAttack...profile.maximumAttack, using: &rng)
            }
        } else if profile.maximumAttack == profile.minimumAttack {
            attackDamage = profile.minimumAttack
        } else {
            attackDamage = 0
        }

        let intuitionRoll = damageService.getRandomDamageReduction(
            stat: defenderEff.instinct.value,
            coefficient: GameMechanicsConstants.intuitionReductionCoefficient,
            using: generator
        )
        let enduranceRoll = damageService.getRandomDamageReduction(
            stat: defenderEff.endurance.value,
            coefficient: GameMechanicsConstants.enduranceReductionCoefficient,
            using: generator
        )
        let enduranceReduction = Int(intuitionRoll + enduranceRoll)

        let defenderArmor = defender.armorValues[bodyPart] ?? 0
        return (Int(strengthDamage), attackDamage, enduranceReduction, defenderArmor)
    }

    /// Mirrors the production damage formula for the debug logger: only the
    /// weapon swing scales with the crit multiplier; STR/END/Armor are flat.
    internal func logBodyPartResult(
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
            attacker: attacker.name, defender: defender.name, bodyPart: bodyPart,
            isAttacked: isAttacked, isDefended: isDefended,
            baseDamage: baseDamage, armor: defenderArmor,
            finalDamage: finalDamage, finalStatus: finalStatus
        )
    }
}

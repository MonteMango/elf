//
//  ElfSnapshotCombatCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Dependencies

public final class ElfSnapshotCombatCalculator: SnapshotCombatCalculator {

    // Properties are module-internal (no `private`) so the resolver methods
    // in `ElfSnapshotCombatCalculator+Resolvers.swift` can reach them. The
    // class itself stays final; nothing exposes these outside the module.
    internal let damageService: any DamageService
    internal let dodgeService: any DodgeService
    internal let critService: any CritService
    internal let enduranceService: any EnduranceService
    internal let buffEffectsCalculator: any BuffEffectsCalculator
    internal let debugLogger: any DebugBattleLogger

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
        defender: CombatantSnapshot,
        using generator: WithRandomNumberGenerator
    ) -> [BodyPart: PointStatus] {
        let attackerEff = buffEffectsCalculator.effectiveAttributes(of: attacker)
        let defenderEff = buffEffectsCalculator.effectiveAttributes(of: defender)
        let allBodyParts: [BodyPart] = [.head, .body, .leftHand, .rightHand, .legs]

        var results: [BodyPart: PointStatus] = [:]
        emitUnattackedStatuses(
            allBodyParts: allBodyParts,
            attackingPoints: attackingPoints,
            defendingPoints: defendingPoints,
            attacker: attacker, defender: defender,
            into: &results
        )

        // Strike-to-body-part mapping: among the attacker's chosen body parts,
        // the i-th in `allBodyParts` enum order is hit by strike i.
        // Strike 0 = primary (right-hand) weapon, strike 1 = off-hand (left)
        // for dual-wield. We iterate strikes in this order so the right
        // weapon's EP draw happens before the left weapon's — matches the
        // design rule "primary checks first, then secondary".
        let orderedAttackedBodyParts = allBodyParts.filter(attackingPoints.contains)
        var defenderRemainingEP = defender.currentEP

        for (strikeIndex, bodyPart) in orderedAttackedBodyParts.enumerated() {
            let profile = strikeProfile(for: strikeIndex, attacker: attacker)
            let isDefended = defendingPoints.contains(bodyPart)
            results[bodyPart] = resolveStrike(
                bodyPart: bodyPart,
                profile: profile,
                isDefended: isDefended,
                defenderRemainingEP: &defenderRemainingEP,
                attacker: attacker, defender: defender,
                attackerEff: attackerEff, defenderEff: defenderEff,
                using: generator
            )
        }

        return results
    }

    // MARK: - Strike resolution helpers

    /// Body parts NOT attacked emit `.nothing` directly. Done in a
    /// separate pass so the strike loop reads as pure per-strike logic.
    private func emitUnattackedStatuses(
        allBodyParts: [BodyPart],
        attackingPoints: Set<BodyPart>,
        defendingPoints: Set<BodyPart>,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        into results: inout [BodyPart: PointStatus]
    ) {
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
    }

    /// Picks the attack profile for a given strike index. Defensive: if the
    /// attacker selected more body parts than there are strikes (shouldn't
    /// happen — bot AI uses `attackPoints` as count), reuse the last strike.
    private func strikeProfile(for strikeIndex: Int, attacker: CombatantSnapshot) -> AttackProfile {
        attacker.attacks[min(strikeIndex, max(0, attacker.attacks.count - 1))]
    }

    /// Single-strike resolution: dodge first (cancels attack), then either
    /// blocked-attack path (if defender chose to block this body part) or
    /// clean-hit path.
    private func resolveStrike(
        bodyPart: BodyPart,
        profile: AttackProfile,
        isDefended: Bool,
        defenderRemainingEP: inout Int,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        attackerEff: HeroAttributes,
        defenderEff: HeroAttributes,
        using generator: WithRandomNumberGenerator
    ) -> PointStatus {
        let dodgeResult = dodgeService.calculateDodge(
            agility: defenderEff.agility.value,
            instinct: attackerEff.instinct.value,
            attackerLevel: attacker.level,
            using: generator
        )
        debugLogger.logDodgeCalculation(
            defender: defender.name,
            result: dodgeResult,
            agility: defenderEff.agility.value,
            instinct: attackerEff.instinct.value
        )

        if dodgeResult.success {
            return resolveDodgedAttack(
                bodyPart: bodyPart, isDefended: isDefended,
                attacker: attacker, defender: defender,
                attackerEff: attackerEff, defenderEff: defenderEff,
                using: generator
            )
        }

        if isDefended {
            // Per-strike block cost. Endurance is constant across the round,
            // but base cost varies by weapon, so we recompute per strike.
            // Attacker's Strength burns effective blocks from the defender
            // (see `GameMechanicsConstants.blocksLostPerAttackerStrength`).
            let blockCost = enduranceService.calculateBlockCost(
                baseCost: profile.epBlockCost,
                defenderEndurance: Int(defenderEff.endurance.value),
                attackerStrength: Int(attackerEff.strength.value)
            )
            return resolveDefendedAttack(
                bodyPart: bodyPart,
                profile: profile,
                blockCost: blockCost,
                defenderRemainingEP: &defenderRemainingEP,
                attacker: attacker, defender: defender,
                attackerEff: attackerEff, defenderEff: defenderEff,
                using: generator
            )
        }

        return resolveHit(
            bodyPart: bodyPart, isDefended: false,
            profile: profile,
            attacker: attacker, defender: defender,
            attackerEff: attackerEff, defenderEff: defenderEff,
            using: generator
        )
    }

    /// Dodge succeeded — still rolls crit (so the "dodged a crit" case shows
    /// in stats / UI), emits `.dodged(wasCrit:)`, no EP, no damage.
    private func resolveDodgedAttack(
        bodyPart: BodyPart,
        isDefended: Bool,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        attackerEff: HeroAttributes,
        defenderEff: HeroAttributes,
        using generator: WithRandomNumberGenerator
    ) -> PointStatus {
        let critResult = critService.calculateCrit(
            power: attackerEff.power.value,
            instinct: defenderEff.instinct.value,
            attackerLevel: attacker.level,
            using: generator
        )
        let finalStatus = PointStatus.dodged(wasCrit: critResult.success)
        debugLogger.logBodyPartCalculation(
            attacker: attacker.name,
            defender: defender.name,
            bodyPart: bodyPart,
            isAttacked: true,
            isDefended: isDefended,
            baseDamage: nil,
            armor: nil,
            finalDamage: nil,
            finalStatus: finalStatus
        )
        return finalStatus
    }
}

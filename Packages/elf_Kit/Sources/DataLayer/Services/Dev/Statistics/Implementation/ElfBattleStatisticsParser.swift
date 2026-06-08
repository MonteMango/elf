//
//  ElfBattleStatisticsParser.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

/// Default `BattleStatisticsParser`. Walks the per-body-part `PointStatus`
/// dictionary and updates the attacker / defender accumulators.
///
/// After the dodge-first refactor, **every** attacked body part triggers a
/// dodge roll upstream in `ElfSnapshotCombatCalculator.calculatePointStatus`,
/// regardless of whether the defender chose to block that part. So every
/// non-`.nothing` status here represents one dodge attempt (success or fail)
/// and one crit attempt — those two counters are hoisted out of the switch
/// to avoid drift across cases.
public struct ElfBattleStatisticsParser: BattleStatisticsParser {

    public init() {}

    @discardableResult
    public func parseStatistics(
        attackingPoints: Set<BodyPart>,
        defendingPoints: Set<BodyPart>,
        results: [BodyPart: PointStatus],
        attackerStats: inout BattleStatisticsAccumulator,
        defenderStats: inout BattleStatisticsAccumulator
    ) -> Int {
        let strengthBefore = attackerStats.strengthDamage
        for bodyPart in attackingPoints {
            guard let status = results[bodyPart] else { continue }
            if case .nothing = status { continue }
            accumulate(
                status: status,
                isDefended: defendingPoints.contains(bodyPart),
                attackerStats: &attackerStats,
                defenderStats: &defenderStats
            )
        }
        return attackerStats.strengthDamage - strengthBefore
    }

    private func accumulate(
        status: PointStatus,
        isDefended: Bool,
        attackerStats: inout BattleStatisticsAccumulator,
        defenderStats: inout BattleStatisticsAccumulator
    ) {
        // Every landed-or-cancelled attack counts as one dodge attempt
        // (resolved up-stream) and one crit attempt (post-dodge roll, even
        // on `.dodged` it runs to populate `wasCrit`).
        defenderStats.dodgeAttempts += 1
        attackerStats.critAttempts += 1

        switch status {
        case .critHit(_, let strengthDamage, _, _, let multiplier, _):
            attackerStats.critSuccesses += 1
            attackerStats.critMultipliers[multiplier, default: 0] += 1
            attackerStats.strengthDamage += strengthDamage
            if isDefended {
                attackerStats.critBlockBreaks += 1
            }

        case .hit(_, let strengthDamage, _, _):
            attackerStats.strengthDamage += strengthDamage

        case .blocked:
            // A crit on a blocked part is emitted as `.critHit` (epSpent > 0),
            // so `.blocked` is always a non-crit block — nothing to record here
            // beyond the dodge/crit attempt counters hoisted above.
            break

        case .weakBlocked(_, let strengthDamage, _, _, let multiplier, _, let wasCrit):
            attackerStats.strengthDamage += strengthDamage
            if wasCrit {
                attackerStats.critSuccesses += 1
                attackerStats.critMultipliers[multiplier, default: 0] += 1
                attackerStats.critBlockBreaks += 1
            }

        case .dodged(let wasCrit):
            defenderStats.dodgeSuccesses += 1
            if wasCrit {
                attackerStats.critSuccesses += 1
                attackerStats.critsDodged += 1
            }

        case .nothing:
            break
        }
    }
}

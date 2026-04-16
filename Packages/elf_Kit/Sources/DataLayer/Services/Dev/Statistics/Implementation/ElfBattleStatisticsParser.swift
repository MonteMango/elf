//
//  ElfBattleStatisticsParser.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Default implementation of BattleStatisticsParser
public final class ElfBattleStatisticsParser: BattleStatisticsParser {

    public init() {}

    public func parseStatistics(
        attackingPoints: Set<BodyPart>,
        defendingPoints: Set<BodyPart>,
        results: [BodyPart: PointStatus],
        attackerCritAttempts: inout Int,
        attackerCritSuccesses: inout Int,
        attackerCritMultipliers: inout [Double: Int],
        attackerCritBlockBreaks: inout Int,
        attackerCritsDodged: inout Int,
        defenderDodgeAttempts: inout Int,
        defenderDodgeSuccesses: inout Int,
        attackerStrengthDamage: inout Int
    ) {
        for bodyPart in attackingPoints {
            guard let status = results[bodyPart] else { continue }

            // Check if this body part was defended
            let isDefended = defendingPoints.contains(bodyPart)

            switch status {
            case .critHit(_, let strengthDamage, _, let multiplier):
                // Attacker attempted crit and succeeded
                attackerCritAttempts += 1
                attackerCritSuccesses += 1
                attackerCritMultipliers[multiplier, default: 0] += 1
                attackerStrengthDamage += strengthDamage
                // If defended, crit broke the block - no dodge attempt
                if isDefended {
                    attackerCritBlockBreaks += 1
                } else {
                    // Undefended attack - dodge was attempted but failed
                    defenderDodgeAttempts += 1
                }

            case .hit(_, let strengthDamage, _):
                // Attacker attempted crit but failed (normal hit)
                attackerCritAttempts += 1
                attackerStrengthDamage += strengthDamage
                // Undefended attack - dodge was attempted but failed
                defenderDodgeAttempts += 1

            case .blocked(let wasCrit):
                // Defended attack - no dodge attempt (only crit check for block break)
                attackerCritAttempts += 1
                if wasCrit {
                    attackerCritSuccesses += 1
                }

            case .dodged(let wasCrit):
                // Undefended attack - dodge was attempted and succeeded
                defenderDodgeAttempts += 1
                defenderDodgeSuccesses += 1
                attackerCritAttempts += 1
                if wasCrit {
                    attackerCritSuccesses += 1
                    attackerCritsDodged += 1
                }

            case .nothing:
                // No attack happened (shouldn't occur for attackingPoints)
                break
            }
        }
    }
}

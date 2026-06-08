//
//  DefaultPointStatusFormatter.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class DefaultPointStatusFormatter: PointStatusFormatter {

    public init() {}

    public func shortLabel(for status: PointStatus) -> String? {
        switch status {
        case .dodged:
            return "dodge"
        case .hit:
            return "\(status.damageTakenValue)"
        case .critHit:
            return "crit \(status.damageTakenValue)"
        case .blocked:
            return "block"
        case .weakBlocked(_, _, _, _, _, _, let wasCrit):
            return wasCrit ? "weak \(status.damageTakenValue)!" : "weak \(status.damageTakenValue)"
        case .nothing:
            return nil
        }
    }

    public func debugLine(for status: PointStatus) -> String {
        switch status {
        case .blocked(let epSpent):
            return "🛡️ BLOCKED (-\(epSpent) EP)"
        case .hit(let weaponDamage, let strengthDamage, let enduranceReduction, let defenderArmor):
            return "💥 HIT (\(status.damageTakenValue) damage: weapon=\(weaponDamage) str=\(strengthDamage) end_red=\(enduranceReduction) armor=\(defenderArmor))"
        case .critHit(let weaponDamage, let strengthDamage, let enduranceReduction, let defenderArmor, let multiplier, let epSpent):
            let epSuffix = epSpent > 0 ? " -\(epSpent) EP" : ""
            return "💥💥 CRIT HIT (\(status.damageTakenValue) damage: weapon=\(weaponDamage)x\(multiplier) str=\(strengthDamage) end_red=\(enduranceReduction) armor=\(defenderArmor)\(epSuffix))"
        case .weakBlocked(let weaponDamage, let strengthDamage, let enduranceReduction, let defenderArmor, let multiplier, _, let wasCrit):
            let critTag = wasCrit ? " crit×\(multiplier)" : ""
            return "🛡️💢 WEAK BLOCK (\(status.damageTakenValue) damage\(critTag): weapon=\(weaponDamage) str=\(strengthDamage) end_red=\(enduranceReduction) armor=\(defenderArmor))"
        case .dodged:
            return "💨 DODGED"
        case .nothing:
            return "➖ Nothing"
        }
    }
}

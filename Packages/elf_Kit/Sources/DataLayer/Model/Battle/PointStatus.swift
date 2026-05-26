//
//  PointStatus.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.08.25.
//

import Foundation

public enum PointStatus: Sendable, Equatable {
    case blocked(wasCrit: Bool, epSpent: Int)
    case hit(weaponDamage: Int, strengthDamage: Int, enduranceReduction: Int, defenderArmor: Int)
    case critHit(weaponDamage: Int, strengthDamage: Int, enduranceReduction: Int, defenderArmor: Int, multiplier: Double, epSpent: Int)
    case dodged(wasCrit: Bool)
    /// Exhausted defender (EP == 0 + Exhausted debuff) absorbs the strike
    /// without any EP cost, but only the final damage is reduced — the
    /// pre-reduction components (weaponDamage, strengthDamage,
    /// enduranceReduction, defenderArmor) are preserved so logs and stats
    /// can show what the full hit would have been. `finalDamage` is the
    /// already-clamped, already-halved value the defender takes.
    case weakBlocked(weaponDamage: Int, strengthDamage: Int, enduranceReduction: Int, defenderArmor: Int, multiplier: Double, finalDamage: Int, wasCrit: Bool)
    case nothing

    /// EP cost incurred by the defender for this point's resolution.
    public var epSpentValue: Int {
        switch self {
        case .blocked(_, let epSpent): epSpent
        case .critHit(_, _, _, _, _, let epSpent): epSpent
        case .hit, .dodged, .nothing, .weakBlocked: 0
        }
    }

    /// Actual damage the defender takes to HP from this strike. Mirrors the
    /// production damage formula used by `ElfDamageService.calculateTotalDamage`
    /// — keep them in sync. `.weakBlocked` carries its already-halved final
    /// damage so no extra math is needed here.
    public var damageTakenValue: Int {
        switch self {
        case .hit(let weaponDmg, let strengthDmg, let endRed, let armor):
            return max(0, weaponDmg + strengthDmg - endRed - armor)
        case .critHit(let weaponDmg, let strengthDmg, let endRed, let armor, let multiplier, _):
            let amplifiedWeapon = Int(Double(weaponDmg) * multiplier)
            return max(0, amplifiedWeapon + strengthDmg - endRed - armor)
        case .weakBlocked(_, _, _, _, _, let finalDamage, _):
            return finalDamage
        case .blocked, .dodged, .nothing:
            return 0
        }
    }

    /// Damage soaked by the defender's `Endurance` for this strike, before
    /// armor and any post-chain halving. `0` for resolutions where no
    /// endurance roll occurred (`.blocked`, `.dodged`, `.nothing`).
    public var enduranceReductionValue: Int {
        switch self {
        case .hit(_, _, let endRed, _): endRed
        case .critHit(_, _, let endRed, _, _, _): endRed
        case .weakBlocked(_, _, let endRed, _, _, _, _): endRed
        case .blocked, .dodged, .nothing: 0
        }
    }
}

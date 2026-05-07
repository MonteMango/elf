//
//  PointStatus.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.08.25.
//

import Foundation

public enum PointStatus: Sendable, Equatable {
    case blocked(wasCrit: Bool, epSpent: Int)
    case hit(weaponDamage: Int, strengthDamage: Int, defenderArmor: Int)
    case critHit(weaponDamage: Int, strengthDamage: Int, defenderArmor: Int, multiplier: Double, epSpent: Int)
    case dodged(wasCrit: Bool)
    case nothing

    /// EP cost incurred by the defender for this point's resolution.
    public var epSpentValue: Int {
        switch self {
        case .blocked(_, let epSpent): epSpent
        case .critHit(_, _, _, _, let epSpent): epSpent
        case .hit, .dodged, .nothing: 0
        }
    }
}

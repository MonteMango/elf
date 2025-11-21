//
//  PointStatus.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.08.25.
//

import Foundation

public enum PointStatus: Sendable, Equatable {
    case blocked(wasCrit: Bool)
    case hit(weaponDamage: Int, strengthDamage: Int, defenderArmor: Int)
    case critHit(weaponDamage: Int, strengthDamage: Int, defenderArmor: Int, multiplier: Double)
    case dodged(wasCrit: Bool)
    case nothing
}

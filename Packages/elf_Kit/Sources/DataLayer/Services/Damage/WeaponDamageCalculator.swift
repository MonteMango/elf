//
//  WeaponDamageCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Calculates damage based on equipped weapon
public protocol WeaponDamageCalculator: Sendable {

    /// Get weapon damage range for a specific weapon
    ///
    /// - Parameter weaponId: The weapon's UUID (nil for unarmed)
    /// - Returns: Tuple of (minDmg, maxDmg) or nil if invalid
    func getWeaponDamage(weaponId: UUID?) -> (minDmg: Int16, maxDmg: Int16)?
}

//
//  DamageService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public protocol DamageService: Sendable {
    func getMinMaxStrengthDamage(_ strengthAttribute: Int16) async -> (minDmg: Int16, maxDmg: Int16)?
    func getWeaponDamage(weaponId: UUID?) async -> (minDmg: Int16, maxDmg: Int16)?

    /// Get random strength damage value based on weighted distribution
    func getRandomStrengthDamage(_ strengthAttribute: Int16) async -> Int16

    /// Get random weapon damage value in range [minDamage, maxDamage]
    func getRandomWeaponDamage(weaponId: UUID?) async -> Int16

    /// Calculate total damage from point status results
    func calculateTotalDamage(from pointStatus: [BodyPart: PointStatus]) -> Int
}

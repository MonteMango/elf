//
//  AttackProfile.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// One strike's worth of damage and EP-cost data.
///
/// `CombatantSnapshot.attacks` carries an array of these — one per attack
/// point per round. For an elf, the array is built from the equipped
/// `WeaponConfiguration`: index 0 is the primary (right-hand) weapon,
/// index 1 (when dual-wielding) is the off-hand weapon. For a monster,
/// profiles are decoded from `Monster.rightAttack` / `Monster.leftAttack`.
public struct AttackProfile: Sendable, Hashable, Codable {

    /// Lower bound of weapon damage roll for this strike.
    public let minimumAttack: Int

    /// Upper bound of weapon damage roll for this strike.
    public let maximumAttack: Int

    /// Base EP cost imposed on the defender when blocking this strike,
    /// before endurance reduction.
    public let epBlockCost: Int

    public init(minimumAttack: Int, maximumAttack: Int, epBlockCost: Int) {
        self.minimumAttack = minimumAttack
        self.maximumAttack = maximumAttack
        self.epBlockCost = epBlockCost
    }
}

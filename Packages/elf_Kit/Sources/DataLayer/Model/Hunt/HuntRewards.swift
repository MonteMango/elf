//
//  HuntRewards.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import Foundation

/// Rewards obtained from defeating a monster
public struct HuntRewards: Sendable, Equatable {
    /// Experience points gained
    public let experience: Int

    /// Materials dropped with their amounts
    public let materials: [MaterialReward]

    /// Weapon ID if a weapon was dropped (nil if no weapon dropped)
    public let weaponId: String?

    /// Armor ID if armor was dropped (nil if no armor dropped)
    public let armorId: String?

    public init(
        experience: Int,
        materials: [MaterialReward],
        weaponId: String? = nil,
        armorId: String? = nil
    ) {
        self.experience = experience
        self.materials = materials
        self.weaponId = weaponId
        self.armorId = armorId
    }
}

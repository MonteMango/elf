//
//  HuntRewards.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import Foundation

/// Rewards obtained from defeating a monster
/// Items are pre-resolved during reward calculation — no repository lookups needed downstream
public struct HuntRewards: Sendable, Equatable {
    /// Experience points gained
    public let experience: Int

    /// Materials dropped with their amounts
    public let materials: [MaterialReward]

    /// Resolved weapon if a weapon was dropped
    public let weapon: ElfWeaponItem?

    /// Resolved armor if armor was dropped
    public let armor: ElfDefenseItem?

    public init(
        experience: Int,
        materials: [MaterialReward],
        weapon: ElfWeaponItem? = nil,
        armor: ElfDefenseItem? = nil
    ) {
        self.experience = experience
        self.materials = materials
        self.weapon = weapon
        self.armor = armor
    }
}

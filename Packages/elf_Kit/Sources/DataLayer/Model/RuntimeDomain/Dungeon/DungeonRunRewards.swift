//
//  DungeonRunRewards.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Run-scoped rewards accrued while clearing dungeon rooms. Held on
/// `DungeonSession` and flushed to `GameSession` when the run ends (Finish or
/// hero death).
///
/// Holds **resolved** drop instances (`ElfWeaponItem`/`ElfDefenseItem`), like
/// `HuntRewards` — so the live ledger is self-sufficient (it can answer "what did
/// I win" without an `ItemsRepository`) and flush hands the player the same
/// instances the result overlay showed. Persistence goes through the
/// `DungeonRunRewardsSaveData` id-reference DTO, matching how every other runtime
/// type round-trips (`RuntimeDomain ↔ *SaveData`, resolved via repositories).
public struct DungeonRunRewards: Sendable, Equatable {

    public var experience: Int
    public var materials: [MaterialReward]
    public var weapons: [ElfWeaponItem]
    public var armor: [ElfDefenseItem]

    public init(
        experience: Int = 0,
        materials: [MaterialReward] = [],
        weapons: [ElfWeaponItem] = [],
        armor: [ElfDefenseItem] = []
    ) {
        self.experience = experience
        self.materials = materials
        self.weapons = weapons
        self.armor = armor
    }

    public static let empty = DungeonRunRewards()

    /// Folds one battle's `HuntRewards` into the ledger. Materials are merged by
    /// id (so repeated drops of the same material stay one summed entry instead of
    /// bloating the ledger); weapon/armor instances are distinct, so they append.
    public mutating func accrue(_ rewards: HuntRewards) {
        experience += rewards.experience
        for material in rewards.materials {
            if let index = materials.firstIndex(where: { $0.id == material.id }) {
                materials[index] = MaterialReward(
                    id: material.id,
                    amount: materials[index].amount + material.amount
                )
            } else {
                materials.append(material)
            }
        }
        if let weapon = rewards.weapon { weapons.append(weapon) }
        if let armorItem = rewards.armor { armor.append(armorItem) }
    }
}

//
//  DungeonRunRewardsSaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// On-disk form of `DungeonRunRewards` — rewards accrued during a dungeon run.
/// Weapons/armor are stored as id-reference DTOs (resolved back via
/// `ItemsRepository` on load), mirroring inventory persistence. Materials are
/// already id + amount. This keeps the runtime ledger free of persistence
/// concerns (`RuntimeDomain ↔ *SaveData`, the project-wide round-trip pattern).
public struct DungeonRunRewardsSaveData: Codable, Sendable, Equatable {

    public let experience: Int
    public let materials: [MaterialReward]
    public let weapons: [WeaponSaveData]
    public let armor: [DefenseSaveData]

    public init(
        experience: Int,
        materials: [MaterialReward],
        weapons: [WeaponSaveData],
        armor: [DefenseSaveData]
    ) {
        self.experience = experience
        self.materials = materials
        self.weapons = weapons
        self.armor = armor
    }

    public static let empty = DungeonRunRewardsSaveData(
        experience: 0, materials: [], weapons: [], armor: []
    )

    /// Snapshot a runtime ledger into its on-disk form.
    public init(from rewards: DungeonRunRewards) {
        self.experience = rewards.experience
        self.materials = rewards.materials
        self.weapons = rewards.weapons.map(WeaponSaveData.init(from:))
        self.armor = rewards.armor.map(DefenseSaveData.init(from:))
    }

    /// Rebuild the runtime ledger, resolving weapon/armor ids via the catalog.
    /// A drop whose id no longer resolves (catalog drift) is skipped with a log
    /// rather than vanishing silently.
    public func toRewards(using repository: ItemsRepository) -> DungeonRunRewards {
        DungeonRunRewards(
            experience: experience,
            materials: materials,
            weapons: weapons.compactMap { saved in
                let resolved = saved.toElfWeaponItem(using: repository)
                #if DEBUG
                if resolved == nil {
                    print("[DungeonRunRewards] banked weapon \(saved.itemId) no longer resolves — dropped")
                }
                #endif
                return resolved
            },
            armor: armor.compactMap { saved in
                let resolved = saved.toElfDefenseItem(using: repository)
                #if DEBUG
                if resolved == nil {
                    print("[DungeonRunRewards] banked armor \(saved.itemId) no longer resolves — dropped")
                }
                #endif
                return resolved
            }
        )
    }
}

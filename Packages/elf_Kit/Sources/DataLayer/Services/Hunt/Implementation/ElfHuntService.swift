//
//  ElfHuntService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Dependencies
import Foundation

public final class ElfHuntService: HuntService {

    private let itemsRepository: any ItemsRepository

    public init() {
        @Dependency(\.itemsRepository) var itemsRepository
        self.itemsRepository = itemsRepository
    }

    // MARK: - HuntService

    public func calculateRewards(for monster: Monster) -> HuntRewards {
        let experience = rollExperience(from: monster.expReward)
        let materials = rollMaterials(from: monster.drops.materials)

        // Resolve weapon from repository
        var weapon: ElfWeaponItem?
        if let weaponIdStr = rollItemDrop(from: monster.drops.weapons),
           let weaponId = UUID(uuidString: weaponIdStr),
           let weaponItem = itemsRepository.getHeroItem(ItemID(rawValue: weaponId)) as? WeaponItem {
            weapon = ElfWeaponItem(weaponItem: weaponItem)
        }

        // Resolve armor from repository
        var armor: ElfDefenseItem?
        if let armorIdStr = rollItemDrop(from: monster.drops.armor),
           let armorId = UUID(uuidString: armorIdStr),
           let defenseItem = itemsRepository.getHeroItem(ItemID(rawValue: armorId)) as? DefenseItem {
            armor = ElfDefenseItem(defenseItem: defenseItem)
        }

        return HuntRewards(
            experience: experience,
            materials: materials,
            weapon: weapon,
            armor: armor
        )
    }

    // MARK: - Private Helpers

    /// Roll experience based on chance distribution
    private func rollExperience(from expReward: [ChanceAmount]) -> Int {
        rollAmount(from: expReward)
    }

    /// Roll material drops based on their chance distributions
    private func rollMaterials(from materialDrops: [MaterialDrop]) -> [MaterialReward] {
        var rewards: [MaterialReward] = []

        for drop in materialDrops {
            let amount = rollAmount(from: drop.chances)
            if amount > 0 {
                rewards.append(MaterialReward(id: drop.id, amount: amount))
            }
        }

        return rewards
    }

    /// Roll for an item drop (weapon or armor)
    /// Returns the item ID if drop succeeds, nil otherwise
    private func rollItemDrop(from items: [ItemDrop]) -> String? {
        for item in items {
            let roll = Double.random(in: 0..<1)
            if roll < item.chance {
                return item.id
            }
        }
        return nil
    }

    /// Generic method to roll an amount based on chance distribution
    /// The chances array should sum to 1.0 (100%)
    ///
    /// RNG boundary note: this uses the bare system RNG on purpose. The
    /// seedable `\.withRandomNumberGenerator` path + `WeightedSamplingService`
    /// cover the **combat** determinism work (per-battle reproducible sweeps);
    /// world-gen / activity rolls (hunt, gathering, NPC generation, house
    /// assignment) are intentionally **off** that determinism path and stay on
    /// `Double.random` / `Int.random`. Don't migrate this to the combat
    /// sampler without a deliberate decision to make world-gen reproducible.
    private func rollAmount(from chances: [ChanceAmount]) -> Int {
        guard !chances.isEmpty else { return 0 }

        let roll = Double.random(in: 0..<1)
        var cumulativeChance: Double = 0

        for chanceAmount in chances {
            cumulativeChance += chanceAmount.chance
            if roll < cumulativeChance {
                return chanceAmount.amount
            }
        }

        // Fallback to last amount if rounding issues occur
        return chances.last?.amount ?? 0
    }
}

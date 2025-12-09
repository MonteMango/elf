//
//  ElfHuntService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

public final class ElfHuntService: HuntService {

    private let monsterRepository: MonsterRepository

    public init(monsterRepository: MonsterRepository) {
        self.monsterRepository = monsterRepository
    }

    // MARK: - HuntService

    public func getAvailableMonsters(world: WorldType, level: Int) -> [Monster] {
        monsterRepository.getMonsters(world: world, level: level)
    }

    public func selectRandomMonster(world: WorldType, level: Int) -> Monster? {
        monsterRepository.getRandomMonster(world: world, level: level)
    }

    public func calculateRewards(for monster: Monster) -> HuntRewards {
        let experience = rollExperience(from: monster.expReward)
        let materials = rollMaterials(from: monster.drops.materials)
        let weaponId = rollItemDrop(from: monster.drops.weapons)
        let armorId = rollItemDrop(from: monster.drops.armor)

        return HuntRewards(
            experience: experience,
            materials: materials,
            weaponId: weaponId,
            armorId: armorId
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

// MARK: - Sendable Conformance
extension ElfHuntService: @unchecked Sendable {}

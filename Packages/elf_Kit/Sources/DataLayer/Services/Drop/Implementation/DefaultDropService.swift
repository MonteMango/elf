//
//  DefaultDropService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import Foundation

public final class DefaultDropService: DropService {

    private let materialRepository: MaterialRepository
    private let itemsRepository: ItemsRepository

    public init(
        materialRepository: MaterialRepository,
        itemsRepository: ItemsRepository
    ) {
        self.materialRepository = materialRepository
        self.itemsRepository = itemsRepository
    }

    // MARK: - DropService

    public func convertToDropItems(rewards: HuntRewards, didWin: Bool) -> [DropItem] {
        guard didWin else { return [] }

        var dropItems: [DropItem] = []

        // Convert materials
        for materialReward in rewards.materials {
            if let dropItem = createMaterialDropItem(from: materialReward) {
                dropItems.append(dropItem)
            }
        }

        // Convert weapon if dropped
        if let weaponIdString = rewards.weaponId,
           let weaponId = UUID(uuidString: weaponIdString),
           let dropItem = createWeaponDropItem(id: weaponId) {
            dropItems.append(dropItem)
        }

        // Convert armor if dropped
        if let armorIdString = rewards.armorId,
           let armorId = UUID(uuidString: armorIdString),
           let dropItem = createArmorDropItem(id: armorId) {
            dropItems.append(dropItem)
        }

        return dropItems
    }

    // MARK: - Private Helpers

    private func createMaterialDropItem(from reward: MaterialReward) -> DropItem? {
        guard let material = materialRepository.getMaterial(id: reward.id) else {
            return nil
        }

        return DropItem(
            id: UUID(),
            itemType: .material,
            name: material.title,
            icon: material.imageName,
            rarity: .common,  // Materials are common by default
            quantity: reward.amount
        )
    }

    private func createWeaponDropItem(id: UUID) -> DropItem? {
        guard let weapon = itemsRepository.getHeroItem(id) else {
            return nil
        }

        return DropItem(
            id: UUID(),
            itemType: .weapon,
            name: weapon.title,
            icon: "sword",  // Default weapon icon
            rarity: rarityFromTier(weapon.tier),
            quantity: 1
        )
    }

    private func createArmorDropItem(id: UUID) -> DropItem? {
        guard let armor = itemsRepository.getHeroItem(id) else {
            return nil
        }

        return DropItem(
            id: UUID(),
            itemType: .armor,
            name: armor.title,
            icon: "shield",  // Default armor icon
            rarity: rarityFromTier(armor.tier),
            quantity: 1
        )
    }

    /// Convert item tier to rarity
    /// Tier 1-2: common, Tier 3: uncommon, Tier 4: rare, Tier 5: epic, Tier 6+: legendary
    private func rarityFromTier(_ tier: Int16) -> ItemRarity {
        switch tier {
        case 1...2:
            return .common
        case 3:
            return .uncommon
        case 4:
            return .rare
        case 5:
            return .epic
        default:
            return .legendary
        }
    }
}

// MARK: - Sendable Conformance
// Thread-safe: All stored properties are immutable (let) after initialization.
// All dependencies are Sendable protocols: MaterialRepository, ItemsRepository.
extension DefaultDropService: @unchecked Sendable {}

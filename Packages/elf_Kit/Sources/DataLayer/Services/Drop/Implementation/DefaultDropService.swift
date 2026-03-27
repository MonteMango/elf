//
//  DefaultDropService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import Foundation

public final class DefaultDropService: DropService {

    private let materialRepository: any Repository<Material>
    private let itemsRepository: ItemsRepository

    public init(
        materialRepository: any Repository<Material>,
        itemsRepository: ItemsRepository
    ) {
        self.materialRepository = materialRepository
        self.itemsRepository = itemsRepository
    }

    // MARK: - DropService

    public func convertToDropItems(rewards: HuntRewards, didWin: Bool) async -> [DropItem] {
        guard didWin else { return [] }

        var dropItems: [DropItem] = []

        // Convert materials
        for materialReward in rewards.materials {
            if let dropItem = await createMaterialDropItem(from: materialReward) {
                dropItems.append(dropItem)
            }
        }

        // Convert weapon if dropped
        if let weaponIdString = rewards.weaponId,
           let weaponId = UUID(uuidString: weaponIdString),
           let dropItem = await createWeaponDropItem(id: weaponId) {
            dropItems.append(dropItem)
        }

        // Convert armor if dropped
        if let armorIdString = rewards.armorId,
           let armorId = UUID(uuidString: armorIdString),
           let dropItem = await createArmorDropItem(id: armorId) {
            dropItems.append(dropItem)
        }

        return dropItems
    }

    // MARK: - Private Helpers

    private func createMaterialDropItem(from reward: MaterialReward) async -> DropItem? {
        guard let material = await materialRepository.getById(id: reward.id) else {
            return nil
        }

        return DropItem(
            id: UUID(),
            itemType: .material,
            name: material.title,
            icon: material.imageName,
            tier: .common,
            quantity: reward.amount
        )
    }

    private func createWeaponDropItem(id: UUID) async -> DropItem? {
        guard let weapon = await itemsRepository.getHeroItem(id) else {
            return nil
        }

        return DropItem(
            id: UUID(),
            itemType: .weapon,
            name: weapon.title,
            icon: "sword",
            tier: itemTier(from: weapon.tier),
            quantity: 1
        )
    }

    private func createArmorDropItem(id: UUID) async -> DropItem? {
        guard let armor = await itemsRepository.getHeroItem(id) else {
            return nil
        }

        return DropItem(
            id: UUID(),
            itemType: .armor,
            name: armor.title,
            icon: "shield",
            tier: itemTier(from: armor.tier),
            quantity: 1
        )
    }

    private func itemTier(from tier: Int16) -> ItemTier {
        guard let result = ItemTier(rawValue: Int(tier)) else {
            assertionFailure("Unknown item tier: \(tier)")
            return .common
        }
        return result
    }
}

//
//  DefaultDropService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import Dependencies
import Foundation

public final class DefaultDropService: DropService {

    private let materialRepository: any Repository<Material>

    public init() {
        @Dependency(\.materialRepository) var materialRepository
        self.materialRepository = materialRepository
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

        // Convert weapon if dropped (already resolved)
        if let weapon = rewards.weapon, let weaponItem = weapon.item as? WeaponItem {
            dropItems.append(DropItem(
                id: UUID(),
                itemType: .weapon,
                name: weaponItem.title,
                icon: "sword",
                tier: itemTier(from: weaponItem.tier),
                quantity: 1
            ))
        }

        // Convert armor if dropped (already resolved)
        if let armor = rewards.armor, let defenseItem = armor.item as? DefenseItem {
            dropItems.append(DropItem(
                id: UUID(),
                itemType: .armor,
                name: defenseItem.title,
                icon: "shield",
                tier: itemTier(from: defenseItem.tier),
                quantity: 1
            ))
        }

        return dropItems
    }

    // MARK: - Private Helpers

    private func createMaterialDropItem(from reward: MaterialReward) -> DropItem? {
        guard let material = materialRepository.getById(id: reward.id) else {
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

    private func itemTier(from tier: Int16) -> ItemTier {
        guard let result = ItemTier(rawValue: Int(tier)) else {
            assertionFailure("Unknown item tier: \(tier)")
            return .common
        }
        return result
    }
}

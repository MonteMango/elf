//
//  ElfArmorService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Dependencies
import Foundation

public final class ElfArmorService: ArmorService {

    private let itemsRepository: any ItemsRepository

    public init() {
        @Dependency(\.itemsRepository) var itemsRepository
        self.itemsRepository = itemsRepository
    }

    public func getAllItemsArmor(for itemIds: [ItemID]) -> [BodyPart: Int16] {
        var armorPoints: [BodyPart: Int16] = [
               .head: 0,
               .leftHand: 0,
               .body: 0,
               .rightHand: 0,
               .legs: 0
           ]

        for id in itemIds {
            guard let item = itemsRepository.getHeroItem(id),
                  let defenseItem = item as? HasPhysicalDefense else {
                continue
            }

            for bodyPart in defenseItem.protectParts {
                armorPoints[bodyPart, default: 0] += defenseItem.physicalDefensePoint
            }
        }

        return armorPoints
    }
}

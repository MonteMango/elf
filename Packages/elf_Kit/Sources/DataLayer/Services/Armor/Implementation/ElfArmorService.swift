//
//  ElfArmorService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public final class ElfArmorService: ArmorService {
    
    private let itemsRepository: ItemsRepository
    
    public init(itemsRepository: ItemsRepository) {
        self.itemsRepository = itemsRepository
    }
    
    public func getAllItemsArmor(for itemIds: [UUID]) async -> [BodyPart: Int16] {
        var armorPoints: [BodyPart: Int16] = [
               .head: 0,
               .leftHand: 0,
               .body: 0,
               .rightHand: 0,
               .legs: 0
           ]
        
        for id in itemIds {
            guard let item = await itemsRepository.getHeroItem(id),
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

// MARK: - Sendable Conformance
extension ElfArmorService: @unchecked Sendable {}

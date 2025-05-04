//
//  ElfArmorService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Combine
import Foundation

public final class ElfArmorService: ArmorService {
    
    private let itemsRepository: ItemsRepository
    private var heroItems: HeroItems?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(itemsRepository: ItemsRepository) {
        self.itemsRepository = itemsRepository
        
        itemsRepository.heroItemsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.heroItems, on: self)
            .store(in: &cancellables)
    }
    
    public func getAllItemsArmor(for itemIds: [HeroItemType : UUID?]) async -> [BodyPart: Int16] {
        guard let heroItems = heroItems else {
            return [:]
        }
        
        var armorPoints: [BodyPart: Int16] = [:]
        
        for (itemType, idOptional) in itemIds {
            guard let id = idOptional else { continue }
            
            let item: HasPhysicalDefense? = {
                switch itemType {
                case .helmet:
                    return heroItems.helmets.first(where: { $0.id == id })
                case .gloves:
                    return heroItems.gloves.first(where: { $0.id == id })
                case .shoes:
                    return heroItems.shoes.first(where: { $0.id == id })
                case .upperBody:
                    return heroItems.upperBodies.first(where: { $0.id == id })
                case .bottomBody:
                    return heroItems.bottomBodies.first(where: { $0.id == id })
                case .shields:
                    return heroItems.shields.first(where: { $0.id == id })
                default:
                    return nil
                }
            }()
            
            guard let defenseItem = item else { continue }
            
            for bodyPart in defenseItem.protectParts {
                if let key = BodyPart(rawValue: bodyPart.rawValue) {
                    armorPoints[key, default: 0] += defenseItem.physicalDefensePoint
                }
            }
        }
        
        return armorPoints
    }
}

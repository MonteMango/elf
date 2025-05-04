//
//  ShieldItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.11.24.
//

import Foundation

public struct ShieldItem: Item, HasPhysicalDefense, Decodable {
    
    public let id: UUID
    public let title: String
    public let tier: Int16
    public let isUnique: Bool?
    
    public let strength: Int16?
    public let agility: Int16?
    public let power: Int16?
    public let instinct: Int16?
    
    public let hitPoints: Int16?
    public let manaPoints: Int16?
    
    public let shieldSpecialAbility: ShieldSpecialAbility?
    
    public let physicalDefensePoint: Int16
    public let protectParts: [BodyPart]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        tier = try container.decode(Int16.self, forKey: .tier)
        isUnique = try container.decodeIfPresent(Bool.self, forKey: .isUnique)
        
        strength = try container.decodeIfPresent(Int16.self, forKey: .strength)
        agility = try container.decodeIfPresent(Int16.self, forKey: .agility)
        power = try container.decodeIfPresent(Int16.self, forKey: .power)
        instinct = try container.decodeIfPresent(Int16.self, forKey: .instinct)
        
        hitPoints = try container.decodeIfPresent(Int16.self, forKey: .hitPoints)
        manaPoints = try container.decodeIfPresent(Int16.self, forKey: .manaPoints)
        
        shieldSpecialAbility = try container.decodeIfPresent(ShieldSpecialAbility.self, forKey: .shieldSpecialAbility)
        physicalDefensePoint = try container.decode(Int16.self, forKey: .physicalDefensePoint)
        
        // Provide default value if protectParts is missing
        protectParts = (try? container.decode([BodyPart].self, forKey: .protectParts)) ??
        [.head, .leftHand, .body, .rightHand, .legs]
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, tier, isUnique,
             strength, agility, power, instinct,
             hitPoints, manaPoints, shieldSpecialAbility,
             physicalDefensePoint, protectParts
    }
}
